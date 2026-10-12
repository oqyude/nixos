#!/usr/bin/env python3
"""Minimal report sink for pxe-infra L6.

POST /report with a JSON body containing at least `run_id`;
the body is validated and written atomically to
REPORTS_DIR/<run_id>.json. Per docs/ARCHITECTURE.md §L6, this
is the only path a run report has to land — the VM can be
destroyed at any moment, but a report that has reached this
sink survives.

Why stdlib only: no extra dependency, no Python-package pin
to drift, no additional security surface. A 1 MB body cap is
plenty for any structured run report per RUNNER-DESIGN.md.
"""
import json
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer

REPORTS_DIR = os.environ.get("REPORTS_DIR", "/var/lib/pxe-infra/reports")
REPORTS_BIND = os.environ.get("REPORTS_BIND", "0.0.0.0")
REPORTS_PORT = int(os.environ.get("REPORTS_PORT", "8080"))
MAX_BODY = 1_000_000  # 1 MB; no legitimate run report is bigger


class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path != "/report":
            self.send_error(404, "POST only at /report")
            return
        length = int(self.headers.get("Content-Length", "0"))
        if length <= 0:
            self.send_error(411, "Length required")
            return
        if length > MAX_BODY:
            self.send_error(413, f"body too large; cap {MAX_BODY}")
            return
        try:
            body = self.rfile.read(length).decode("utf-8")
            data = json.loads(body)
        except (UnicodeDecodeError, json.JSONDecodeError) as e:
            self.send_error(400, f"bad JSON: {e}")
            return
        if not isinstance(data, dict):
            self.send_error(400, "body must be a JSON object")
            return
        run_id = data.get("run_id")
        if not isinstance(run_id, str) or not run_id:
            self.send_error(400, "missing run_id")
            return
        # Path-traversal hardening: only [A-Za-z0-9_-]+ in the id.
        if not all(c.isalnum() or c in "-_" for c in run_id):
            self.send_error(400, "run_id must match [A-Za-z0-9_-]+")
            return
        os.makedirs(REPORTS_DIR, exist_ok=True)
        path = os.path.join(REPORTS_DIR, f"{run_id}.json")
        # Atomic write: temp + rename, so a partial file never
        # appears in the directory listing.
        tmp = path + ".tmp"
        with open(tmp, "w", encoding="utf-8") as f:
            json.dump(data, f, indent=2, sort_keys=True)
        os.replace(tmp, path)
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(
            b'{"status":"ok","path":"' + path.encode() + b'"}'
        )

    def do_GET(self):
        if self.path == "/health":
            self.send_response(200)
            self.send_header("Content-Type", "text/plain")
            self.end_headers()
            self.wfile.write(b"ok")
            return
        self.send_error(404)

    def log_message(self, fmt, *args):
        # Send to stdout for journald; keep them terse.
        sys.stdout.write(
            f"report-sink {self.address_string()} {fmt % args}\n"
        )
        sys.stdout.flush()


def main():
    os.makedirs(REPORTS_DIR, exist_ok=True)
    server = HTTPServer((REPORTS_BIND, REPORTS_PORT), Handler)
    print(
        f"report-sink: serving on {REPORTS_BIND}:{REPORTS_PORT}, "
        f"dir={REPORTS_DIR}",
        flush=True,
    )
    server.serve_forever()


if __name__ == "__main__":
    main()
