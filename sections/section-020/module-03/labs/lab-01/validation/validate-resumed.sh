#!/usr/bin/env bash
# PASS when apps-staging is not suspended and is Ready.
set -uo pipefail
if ! kubectl -n flux-system get kustomization apps-staging >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization apps-staging does not exist. Fix it; do not delete it."
  exit 1
fi
if [ "$(kubectl -n flux-system get kustomization apps-staging -o jsonpath='{.spec.suspend}')" = "true" ]; then
  echo "FAIL: apps-staging is still suspended."
  exit 1
fi
ready="$(kubectl -n flux-system get kustomization apps-staging -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
if [ "$ready" != "True" ]; then
  echo "FAIL: apps-staging is not Ready. Run: flux get kustomizations"
  exit 1
fi
echo "PASS: apps-staging is resumed and Ready."
exit 0
