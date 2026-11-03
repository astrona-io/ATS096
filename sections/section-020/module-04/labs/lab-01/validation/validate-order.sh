#!/usr/bin/env bash
# PASS when consumer depends on chart and both are Ready.
set -uo pipefail
if ! kubectl -n flux-system get kustomization consumer >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization consumer does not exist in flux-system."
  exit 1
fi
if ! kubectl -n flux-system get kustomization consumer -o jsonpath='{range .spec.dependsOn[*]}{.name}{"\n"}{end}' | command grep -qx chart; then
  echo "FAIL: consumer must depend on chart."
  exit 1
fi
for name in chart consumer; do
  ready="$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  if [ "$ready" != "True" ]; then
    echo "FAIL: $name is not Ready. Run: flux get kustomizations"
    exit 1
  fi
done
echo "PASS: consumer waits for chart and both are Ready."
exit 0
