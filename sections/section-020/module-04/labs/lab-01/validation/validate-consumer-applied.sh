#!/usr/bin/env bash
# PASS when the ConfigMap consumer-settings exists in podinfo-staging and the
# podinfo release is deployed.
set -uo pipefail
if ! kubectl -n podinfo-staging get configmap consumer-settings >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap consumer-settings does not exist in podinfo-staging."
  exit 1
fi
ready="$(kubectl -n podinfo-staging get helmrelease podinfo -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$ready" != "True" ]; then
  echo "FAIL: the HelmRelease podinfo in podinfo-staging is not Ready."
  exit 1
fi
if ! kubectl -n podinfo-staging get deployment podinfo >/dev/null 2>&1; then
  echo "FAIL: the Deployment podinfo does not exist in podinfo-staging."
  exit 1
fi
echo "PASS: the release is deployed and the consumer ConfigMap exists."
exit 0
