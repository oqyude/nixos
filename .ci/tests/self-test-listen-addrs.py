import importlib.util
import sys
from pathlib import Path

# Resolve the module next to this script, so the self-test works from any
# working directory (the CI script runs it from the repo root, a developer
# may run it from anywhere).
TARGET = Path(__file__).resolve().parent / "check-listen-addrs.py"
spec = importlib.util.spec_from_file_location("check_listen_addrs", TARGET)
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

cases = {
    "192.168.1.0/24": "bad",
    "0.0.0.0": "ok",
    "127.0.0.1": "ok",
    "100.64.0.0": "ok",
    "127.0.0.1:9101": "ok",
    "224.0.0.1": "bad",
    "255.255.255.255": "bad",
    "[::1]:443": "ok",
}

bad = 0
for addr, expected in cases.items():
    problem = m.classify(addr)
    verdict = "bad" if problem else "ok"
    status = "OK  " if verdict == expected else "FAIL"
    if verdict != expected:
        bad = 1
    print(f"{status} {addr:20} expected={expected} got={verdict} {problem or ''}")

sys.exit(bad)
