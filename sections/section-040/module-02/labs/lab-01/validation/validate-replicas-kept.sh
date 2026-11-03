#!/usr/bin/env bash
# PASS when Flux does not own replicas, the Deployment runs 4 replicas, and
# podinfo-staging is Ready.
set -uo pipefail

owned="$(kubectl -n podinfo-staging get deployment podinfo --show-managed-fields \
  -o jsonpath='{.metadata.managedFields[?(@.manager=="kustomize-controller")].fieldsV1.f:spec}' 2>/dev/null)"
if printf '%s' "$owned" | command grep -q 'f:replicas'; then
  echo "FAIL: kustomize-controller still owns spec.replicas. Remove the field from Git and let Flux apply."
  exit 1
fi
replicas="$(kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
if [ "$replicas" != "4" ]; then
  echo "FAIL: the Deployment has $replicas replicas, expected 4 set by another field manager."
  exit 1
fi
ready="$(kubectl -n flux-system get kustomization podinfo-staging -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$ready" != "True" ]; then
  echo "FAIL: podinfo-staging is not Ready. Run: flux get kustomizations"
  exit 1
fi
echo "PASS: Flux does not own replicas, and the Deployment runs 4 replicas."
exit 0
