#!/usr/bin/env bash
# PASS when the Deployment in Git does not set spec.replicas.
set -uo pipefail

RAW="$(kubectl -n gitea exec deploy/tester -- curl -fsS -u gitops:gitops-password \
  'http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/raw/apps/podinfo/base/deployment.yaml?ref=main' 2>/dev/null)"
if [ -z "$RAW" ]; then
  echo "FAIL: could not read apps/podinfo/base/deployment.yaml from Git."
  exit 1
fi
if printf '%s\n' "$RAW" | command grep -Eq '^[[:space:]]*replicas:'; then
  echo "FAIL: apps/podinfo/base/deployment.yaml in Git still sets replicas."
  exit 1
fi
echo "PASS: the Deployment in Git does not set replicas."
exit 0
