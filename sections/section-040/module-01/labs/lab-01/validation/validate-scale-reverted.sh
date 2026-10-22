#!/usr/bin/env bash
# PASS when a manual scale to 5 is put back to 2 by helm-controller after a
# reconciliation.
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n podinfo-production scale deployment podinfo --replicas=5 >/dev/null
flux reconcile helmrelease podinfo -n podinfo-production --timeout=3m >/dev/null 2>&1 || true

REPLICAS=""
for _ in $(seq 1 30); do
  REPLICAS="$(kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  [ "$REPLICAS" = "2" ] && break
  sleep 3
done
if [ "$REPLICAS" != "2" ]; then
  echo "FAIL: after a manual scale to 5 and a reconciliation, podinfo has $REPLICAS replicas; helm-controller must put it back to 2."
  exit 1
fi

echo "PASS: helm-controller reverted the manual scale to 2 replicas."
exit 0
