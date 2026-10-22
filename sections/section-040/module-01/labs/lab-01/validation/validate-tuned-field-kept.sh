#!/usr/bin/env bash
# PASS when the hand-tuned CPU request of 50m survives a reconciliation.
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

flux reconcile helmrelease podinfo -n podinfo-production --timeout=3m >/dev/null 2>&1 || true
sleep 5

CPU="$(kubectl -n podinfo-production get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null)"
if [ "$CPU" != "50m" ]; then
  echo "FAIL: the CPU request of podinfo is '$CPU' after a reconciliation; the hand-tuned 50m must stay."
  exit 1
fi

echo "PASS: the hand-tuned CPU request of 50m survived the reconciliation."
exit 0
