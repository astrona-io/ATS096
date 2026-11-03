#!/usr/bin/env bash
# PASS when the Flux Kustomization chart applies infrastructure/podinfo-chart
# into podinfo-staging and judges the HelmRelease (wait, or a healthChecks entry).
set -uo pipefail
k() { kubectl -n flux-system get kustomization chart -o jsonpath="$1" 2>/dev/null; }
if ! kubectl -n flux-system get kustomization chart >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization chart does not exist in flux-system."
  exit 1
fi
if [ "$(k '{.spec.path}')" != "./infrastructure/podinfo-chart" ]; then
  echo "FAIL: chart must use the path ./infrastructure/podinfo-chart. It uses '$(k '{.spec.path}')'."
  exit 1
fi
if [ "$(k '{.spec.targetNamespace}')" != "podinfo-staging" ]; then
  echo "FAIL: chart must use targetNamespace podinfo-staging."
  exit 1
fi
wait="$(k '{.spec.wait}')"
hc="$(k '{range .spec.healthChecks[*]}{.kind}/{.name}{"\n"}{end}')"
if [ "$wait" != "true" ] && ! printf '%s\n' "$hc" | command grep -qx 'HelmRelease/podinfo'; then
  echo "FAIL: chart must be Ready only when the release is healthy: set wait: true, or a healthChecks entry for the HelmRelease podinfo."
  exit 1
fi
echo "PASS: chart applies the chart folder and judges the release."
exit 0
