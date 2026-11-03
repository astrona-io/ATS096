#!/usr/bin/env bash
# PASS when the release is Ready, runs in podinfo-app, and is stored in podinfo-staging.
set -uo pipefail

ready="$(kubectl -n podinfo-staging get helmrelease podinfo -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
if [ "$ready" != "True" ]; then
  echo "FAIL: podinfo is not Ready. Run: flux get helmreleases -n podinfo-staging"
  exit 1
fi
if [ -z "$(kubectl -n podinfo-app get deployment podinfo -o name 2>/dev/null)" ]; then
  echo "FAIL: no Deployment podinfo in the namespace podinfo-app."
  exit 1
fi
stored="$(kubectl -n podinfo-staging get secrets -l owner=helm,name=podinfo -o name 2>/dev/null)"
if [ -z "$stored" ]; then
  echo "FAIL: no Helm Secret for podinfo in podinfo-staging."
  exit 1
fi
elsewhere="$(kubectl -n podinfo-app get secrets -l owner=helm -o name 2>/dev/null)"
if [ -n "$elsewhere" ]; then
  echo "FAIL: Helm Secrets were found in podinfo-app: $elsewhere"
  exit 1
fi
echo "PASS: podinfo is Ready in podinfo-app, with its Helm Secrets in podinfo-staging."
exit 0
