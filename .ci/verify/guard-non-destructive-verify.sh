#!/usr/bin/env bash
# Non-destructive verification of ConditionPathIsMountPoint guard logic.
# Creates two test systemd units:
#  1. ConditionPathIsMountPoint=/nonexistent — should FAIL to start
#  2. ConditionPathIsMountPoint=/mnt/services — should SUCCEED (real mount)
# Proves the guard condition is evaluated correctly by systemd.

set -uo pipefail

echo "=== postgresql guard in runtime (real production unit) ==="
systemctl show postgresql -p ConditionPathIsMountPoint -p RequiresMountsFor
echo

echo "=== Test 1: ConditionPathIsMountPoint=/nonexistent (should FAIL) ==="
sudo systemd-run \
  --unit=test-guard-nonexistent \
  --property=ConditionPathIsMountPoint=/nonexistent/path/does/not/exist \
  --property=Type=oneshot \
  --property=ExecStart=/bin/true \
  --no-block 2>&1
sleep 1
STATE1=$(systemctl is-active test-guard-nonexistent 2>&1)
echo "  is-active: $STATE1"
JOURNAL1=$(journalctl -u test-guard-nonexistent -n 5 --no-pager 2>&1 | grep -iE "condition|failed|skipped" | head -3)
echo "  journal: $JOURNAL1"
sudo systemctl reset-failed test-guard-nonexistent 2>/dev/null || true
echo

echo "=== Test 2: ConditionPathIsMountPoint=/mnt/services (should PASS) ==="
sudo systemd-run \
  --unit=test-guard-real \
  --property=ConditionPathIsMountPoint=/mnt/services \
  --property=Type=oneshot \
  --property=ExecStart=/bin/true \
  --no-block 2>&1
sleep 1
STATE2=$(systemctl is-active test-guard-real 2>&1)
echo "  is-active: $STATE2"
JOURNAL2=$(journalctl -u test-guard-real -n 5 --no-pager 2>&1 | grep -iE "condition|started|active" | head -3)
echo "  journal: $JOURNAL2"
sudo systemctl reset-failed test-guard-real 2>/dev/null || true
echo

echo "=== Verdict ==="
if [ "$STATE1" = "inactive" ] || [ "$STATE1" = "failed" ]; then
  echo "  Test 1 (nonexistent path): CORRECT — unit refused to start (condition false)"
else
  echo "  Test 1 (nonexistent path): UNEXPECTED — unit started despite condition"
fi
if [ "$STATE2" = "active" ] || [ "$STATE2" = "activating" ]; then
  echo "  Test 2 (real mount /mnt/services): CORRECT — unit started (condition true)"
else
  echo "  Test 2 (real mount /mnt/services): UNEXPECTED — unit did not start"
fi
