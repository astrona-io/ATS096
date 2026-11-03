#!/usr/bin/env bash
# PASS when the Secret podinfo-credentials in podinfo-staging holds the
# decrypted message, and the file in Git is still encrypted.
set -uo pipefail

NAMESPACE="podinfo-staging"
EXPECTED="sealed-by-sops"

VALUE=""
for _ in $(seq 1 30); do
  VALUE="$(kubectl -n "$NAMESPACE" get secret podinfo-credentials -o jsonpath='{.data.message}' 2>/dev/null | base64 -d 2>/dev/null)"
  [ "$VALUE" = "$EXPECTED" ] && break
  sleep 3
done
if [ "$VALUE" != "$EXPECTED" ]; then
  echo "FAIL: the Secret podinfo-credentials in $NAMESPACE does not hold the message $EXPECTED. Did Flux decrypt and apply it?"
  exit 1
fi

RAW="$(kubectl -n gitea exec deploy/tester -- \
  curl -fsS -u gitops:gitops-password \
  "http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/raw/apps/podinfo/base/secret.sops.yaml?ref=main" 2>/dev/null)"
if ! printf '%s' "$RAW" | grep -q '^sops:'; then
  echo "FAIL: apps/podinfo/base/secret.sops.yaml in Git is not encrypted with sops."
  exit 1
fi
if printf '%s' "$RAW" | grep -q "$EXPECTED"; then
  echo "FAIL: the plain text value appears in apps/podinfo/base/secret.sops.yaml in Git. Keep the file encrypted."
  exit 1
fi

echo "PASS: the Secret holds the decrypted message and the file in Git stays encrypted."
exit 0
