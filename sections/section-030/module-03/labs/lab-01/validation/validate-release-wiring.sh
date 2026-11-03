#!/usr/bin/env bash
# PASS when hello reads hello-message into the path message and has a
# kustomize post-renderer patch.
set -uo pipefail

ns=podinfo-staging
get() { kubectl -n "$ns" get helmrelease hello -o jsonpath="$1" 2>/dev/null; }

if [ -z "$(get '{.metadata.name}')" ]; then
  echo "FAIL: no HelmRelease hello in $ns."
  exit 1
fi
if [ "$(get '{.spec.chart.spec.sourceRef.kind}')" != "GitRepository" ]; then
  echo "FAIL: the chart must come from the GitRepository fleet."
  exit 1
fi
if [ "$(get '{.spec.valuesFrom[?(@.name=="hello-message")].targetPath}')" != "message" ]; then
  echo "FAIL: valuesFrom must read the ConfigMap hello-message into targetPath message."
  exit 1
fi
if [ -n "$(get '{.spec.values}')" ]; then
  echo "FAIL: do not set the message with spec.values."
  exit 1
fi
patches="$(get '{.spec.postRenderers[*].kustomize.patches}')"
if [ -z "$patches" ]; then
  echo "FAIL: add a kustomize post-renderer with a patch."
  exit 1
fi
echo "PASS: hello reads hello-message into message and has a post-renderer patch."
exit 0
