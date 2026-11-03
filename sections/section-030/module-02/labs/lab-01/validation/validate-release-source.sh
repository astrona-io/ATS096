#!/usr/bin/env bash
# PASS when the HelmRelease hello takes the chart from the GitRepository fleet.
set -uo pipefail

ns=podinfo-staging
get() { kubectl -n "$ns" get helmrelease hello -o jsonpath="$1" 2>/dev/null; }

if [ -z "$(get '{.metadata.name}')" ]; then
  echo "FAIL: no HelmRelease hello in $ns."
  exit 1
fi
kind="$(get '{.spec.chart.spec.sourceRef.kind}')"
name="$(get '{.spec.chart.spec.sourceRef.name}')"
chart="$(get '{.spec.chart.spec.chart}')"
strategy="$(get '{.spec.chart.spec.reconcileStrategy}')"
files="$(get '{.spec.chart.spec.valuesFiles}')"
if [ "$kind" != "GitRepository" ] || [ "$name" != "fleet" ]; then
  echo "FAIL: the chart source must be GitRepository fleet. It is: $kind/$name"
  exit 1
fi
if [ "$chart" != "./charts/hello" ]; then
  echo "FAIL: the chart path must be ./charts/hello. It is: '$chart'"
  exit 1
fi
if [ "$strategy" != "Revision" ]; then
  echo "FAIL: reconcileStrategy must be Revision. It is: '$strategy'"
  exit 1
fi
if ! printf '%s' "$files" | command grep -q 'values-staging.yaml'; then
  echo "FAIL: valuesFiles must include values-staging.yaml. It is: '$files'"
  exit 1
fi
echo "PASS: hello takes ./charts/hello from GitRepository fleet with Revision and a staging values file."
exit 0
