#!/usr/bin/env bash
# PASS when 4 replicas written by another field manager survive a
# reconciliation of the HelmRelease.
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n podinfo-production patch deployment podinfo --type=merge \
  -p '{"spec":{"replicas":4}}' --field-manager=autoscaler >/dev/null
flux reconcile helmrelease podinfo -n podinfo-production --timeout=3m >/dev/null 2>&1 || true
sleep 5
REPLICAS="$(kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
if [ "$REPLICAS" != "4" ]; then
  echo "FAIL: after the autoscaler set 4 replicas and the release reconciled, the Deployment has $REPLICAS. helm-controller must leave spec.replicas alone."
  exit 1
fi
echo "PASS: helm-controller left the 4 replicas alone."
exit 0
