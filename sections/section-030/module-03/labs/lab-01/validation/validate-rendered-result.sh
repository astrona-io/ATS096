#!/usr/bin/env bash
# PASS when hello is Ready and hello-config holds the message and annotation.
set -uo pipefail

ns=podinfo-staging
ready="$(kubectl -n "$ns" get helmrelease hello -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$ready" != "True" ]; then
  echo "FAIL: hello is not Ready. Run: flux get helmreleases -n $ns"
  exit 1
fi
msg="$(kubectl -n "$ns" get configmap hello-config -o jsonpath='{.data.message}' 2>/dev/null)"
if [ "$msg" != "from-configmap" ]; then
  echo "FAIL: hello-config holds message '$msg', expected from-configmap."
  exit 1
fi
owner="$(kubectl -n "$ns" get configmap hello-config -o jsonpath='{.metadata.annotations.owner}' 2>/dev/null)"
if [ "$owner" != "platform" ]; then
  echo "FAIL: hello-config has annotation owner '$owner', expected platform."
  exit 1
fi
echo "PASS: hello is Ready, with the message from the ConfigMap and the annotation owner=platform."
exit 0
