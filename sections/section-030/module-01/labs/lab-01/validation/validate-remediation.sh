#!/usr/bin/env bash
# PASS when the production HelmRelease retries a failed upgrade at least once
# and rolls back (strategy rollback, which is also the default).
set -uo pipefail

field() { kubectl -n podinfo-production get helmrelease podinfo -o jsonpath="$1" 2>/dev/null; }

RETRIES="$(field '{.spec.upgrade.remediation.retries}')"
STRATEGY="$(field '{.spec.upgrade.remediation.strategy}')"

case "$RETRIES" in
  ''|*[!0-9-]*) echo "FAIL: production must set upgrade.remediation.retries to at least 1."; exit 1 ;;
esac
if [ "$RETRIES" -lt 1 ] && [ "$RETRIES" -ge 0 ]; then
  echo "FAIL: production has upgrade.remediation.retries $RETRIES; it must be at least 1."
  exit 1
fi
if [ -n "$STRATEGY" ] && [ "$STRATEGY" != "rollback" ]; then
  echo "FAIL: production uses the remediation strategy $STRATEGY; it must roll back."
  exit 1
fi

echo "PASS: production retries a failed upgrade ($RETRIES) and rolls back."
exit 0
