#!/usr/bin/env bash
# PASS when a hand-made change to the CPU request is put back by
# helm-controller, so drift is still corrected outside the ignored field.
set -uo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

cpu() { kubectl -n podinfo-production get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}' 2>/dev/null; }

BEFORE="$(cpu)"
kubectl -n podinfo-production patch deployment podinfo --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/cpu","value":"333m"}]' >/dev/null
flux reconcile helmrelease podinfo -n podinfo-production --timeout=3m >/dev/null 2>&1 || true

AFTER=""
for _ in $(seq 1 30); do
  AFTER="$(cpu)"
  [ "$AFTER" = "$BEFORE" ] && break
  sleep 3
done
if [ "$AFTER" != "$BEFORE" ]; then
  echo "FAIL: the CPU request is '$AFTER', expected the chart value '$BEFORE'. Drift outside /spec/replicas must still be corrected."
  exit 1
fi
echo "PASS: drift outside the ignored field is still corrected."
exit 0
