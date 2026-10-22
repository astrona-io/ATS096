#!/usr/bin/env bash
# PASS when staging installs through chartRef from the OCIRepository
# podinfo-chart at tag 6.15.0, and both are Ready.
set -uo pipefail

source_field() { kubectl -n podinfo-staging get ocirepository podinfo-chart -o jsonpath="$1" 2>/dev/null; }
release_field() { kubectl -n podinfo-staging get helmrelease podinfo -o jsonpath="$1" 2>/dev/null; }

[ "$(source_field '{.spec.ref.tag}')" = "6.15.0" ] || { echo "FAIL: the OCIRepository podinfo-chart must follow the tag 6.15.0."; exit 1; }
[ "$(release_field '{.spec.chartRef.kind}/{.spec.chartRef.name}')" = "OCIRepository/podinfo-chart" ] || { echo "FAIL: staging must install through chartRef from the OCIRepository podinfo-chart."; exit 1; }

for check in source release; do
  READY=""
  for _ in $(seq 1 60); do
    if [ "$check" = source ]; then
      READY="$(source_field '{.status.conditions[?(@.type=="Ready")].status}')"
    else
      READY="$(release_field '{.status.conditions[?(@.type=="Ready")].status}')"
    fi
    [ "$READY" = "True" ] && break
    sleep 3
  done
  [ "$READY" = "True" ] || { echo "FAIL: the staging $check is not Ready."; exit 1; }
done

echo "PASS: staging installs podinfo 6.15.0 from the OCI registry and is Ready."
exit 0
