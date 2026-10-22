#!/usr/bin/env bash
# PASS when podinfo-staging prunes, is not suspended, is Ready, and the
# leftover ConfigMap podinfo-legacy-settings is gone.
set -uo pipefail

field() { kubectl -n flux-system get kustomization podinfo-staging -o jsonpath="$1" 2>/dev/null; }

[ "$(field '{.spec.prune}')" = "true" ] || { echo "FAIL: podinfo-staging must have prune: true."; exit 1; }
[ "$(field '{.spec.suspend}')" != "true" ] || { echo "FAIL: podinfo-staging is suspended."; exit 1; }

READY=""
for _ in $(seq 1 40); do
  READY="$(field '{.status.conditions[?(@.type=="Ready")].status}')"
  [ "$READY" = "True" ] && break
  sleep 3
done
[ "$READY" = "True" ] || { echo "FAIL: podinfo-staging is not Ready: $(field '{.status.conditions[?(@.type=="Ready")].message}')"; exit 1; }

if kubectl -n podinfo-staging get configmap podinfo-legacy-settings >/dev/null 2>&1; then
  echo "FAIL: the leftover ConfigMap podinfo-legacy-settings still exists in podinfo-staging."
  exit 1
fi

echo "PASS: podinfo-staging prunes and is Ready, and the leftover ConfigMap is gone."
exit 0
