#!/usr/bin/env bash
# PASS when the Flux Kustomization widgets health-checks the Widget gauge and
# carries a healthCheckExprs entry for demo.astrona.io Widget.
set -uo pipefail

name=widgets
if ! kubectl -n flux-system get kustomization "$name" >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization $name does not exist in flux-system."
  exit 1
fi
if [ "$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.spec.wait}')" = "true" ]; then
  echo "FAIL: wait is true, so healthChecks and healthCheckExprs are not used for the Widget."
  exit 1
fi
checks="$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{range .spec.healthChecks[*]}{.kind}/{.name}{"\n"}{end}')"
if ! printf '%s\n' "$checks" | command grep -qx 'Widget/gauge'; then
  echo "FAIL: healthChecks must list the Widget gauge. It lists: $(printf '%s' "$checks" | tr '\n' ' ')"
  exit 1
fi
expr_kind="$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.spec.healthCheckExprs[?(@.kind=="Widget")].apiVersion}')"
if [ "$expr_kind" != "demo.astrona.io/v1" ]; then
  echo "FAIL: healthCheckExprs needs an entry with apiVersion demo.astrona.io/v1 and kind Widget."
  exit 1
fi
for field in current failed; do
  value="$(kubectl -n flux-system get kustomization "$name" -o jsonpath="{.spec.healthCheckExprs[?(@.kind==\"Widget\")].$field}")"
  if [ -z "$value" ]; then
    echo "FAIL: the Widget entry has no $field expression."
    exit 1
  fi
done
echo "PASS: widgets health-checks the Widget gauge with current and failed expressions."
exit 0
