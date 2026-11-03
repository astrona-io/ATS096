#!/usr/bin/env bash
# PASS when the overlay in Git still uses a replacement that reads data.message,
# and the Deployment env PODINFO_UI_MESSAGE in the cluster has the value
# from-replacement.
set -uo pipefail

FILE="$(kubectl -n gitea exec deploy/tester -- \
  curl -fsS -u gitops:gitops-password \
  "http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/raw/apps/podinfo/overlay/kustomization.yaml?ref=main" 2>/dev/null)"
if [ -z "$FILE" ]; then
  echo "FAIL: cannot read apps/podinfo/overlay/kustomization.yaml from gitops/fleet."
  exit 1
fi
if [[ "$FILE" != *"replacements:"* ]]; then
  echo "FAIL: the overlay no longer uses replacements. Fix the replacement; do not remove it."
  exit 1
fi
if [[ "$FILE" != *"fieldPath: data.message"* ]]; then
  echo "FAIL: the replacement must read the key data.message of the ConfigMap podinfo-settings."
  exit 1
fi

VALUE=""
for _ in $(seq 1 40); do
  VALUE="$(kubectl -n podinfo-staging get deployment podinfo \
    -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="PODINFO_UI_MESSAGE")].value}' 2>/dev/null)"
  [ "$VALUE" = "from-replacement" ] && break
  sleep 3
done
if [ "$VALUE" != "from-replacement" ]; then
  echo "FAIL: PODINFO_UI_MESSAGE in the Deployment is '$VALUE'; it must be from-replacement."
  exit 1
fi

echo "PASS: the replacement copies the ConfigMap message into the Deployment."
exit 0
