#!/usr/bin/env bash
# PASS when production has drift detection enabled without ignoring
# /spec/replicas, and a manual scale to 5 is put back to 2 after a reconciliation.
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

field() { kubectl -n podinfo-production get helmrelease podinfo -o jsonpath="$1" 2>/dev/null; }

MODE="$(field '{.spec.driftDetection.mode}')"
[ "$MODE" = "enabled" ] || { echo "FAIL: driftDetection.mode is '$MODE'; it must be enabled."; exit 1; }
if field '{.spec.driftDetection.ignore}' | grep -q '/spec/replicas'; then
  echo "FAIL: production ignores /spec/replicas, so a manual scale would never be reverted."
  exit 1
fi

kubectl -n podinfo-production scale deployment podinfo --replicas=5 >/dev/null
flux reconcile helmrelease podinfo -n podinfo-production --timeout=3m >/dev/null 2>&1 || true

REPLICAS=""
for _ in $(seq 1 30); do
  REPLICAS="$(kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  [ "$REPLICAS" = "2" ] && break
  sleep 3
done
if [ "$REPLICAS" != "2" ]; then
  echo "FAIL: after a manual scale to 5 and a reconciliation, production has $REPLICAS replicas; it must be put back to 2."
  exit 1
fi

echo "PASS: production corrects drift and put a manual scale back to 2."
exit 0
