#!/usr/bin/env bash
# PASS when hello is Ready and the ConfigMap carries the staging message.
set -uo pipefail

ns=podinfo-staging
ready="$(kubectl -n "$ns" get helmrelease hello -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$ready" != "True" ]; then
  echo "FAIL: hello is not Ready. Run: flux get helmreleases -n $ns"
  exit 1
fi
msg="$(kubectl -n "$ns" get configmap hello-config -o jsonpath='{.data.message}' 2>/dev/null)"
if [ "$msg" != "staging" ]; then
  echo "FAIL: hello-config in $ns holds message '$msg', expected staging."
  exit 1
fi
echo "PASS: hello is Ready and hello-config holds staging."
exit 0
