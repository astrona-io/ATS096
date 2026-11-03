#!/usr/bin/env bash
# PASS when shared-settings is owned by team-b, kept its UID, and both stages are Ready.
set -uo pipefail

owner="$(kubectl -n podinfo-staging get configmap shared-settings -o jsonpath='{.metadata.labels.kustomize\.toolkit\.fluxcd\.io/name}' 2>/dev/null)"
if [ "$owner" != "team-b" ]; then
  echo "FAIL: shared-settings is owned by '$owner', expected team-b (or it does not exist)."
  exit 1
fi
now="$(kubectl -n podinfo-staging get configmap shared-settings -o jsonpath='{.metadata.uid}' 2>/dev/null)"
was="$(kubectl -n flux-system get configmap lab-uid-record -o jsonpath='{.data.uid}' 2>/dev/null)"
if [ -z "$was" ] || [ "$now" != "$was" ]; then
  echo "FAIL: shared-settings was recreated. The UID changed from '$was' to '$now'."
  exit 1
fi
for k in team-a team-b; do
  ready="$(kubectl -n flux-system get kustomization "$k" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
  if [ "$ready" != "True" ]; then
    echo "FAIL: $k is not Ready. Run: flux get kustomizations"
    exit 1
  fi
done
echo "PASS: shared-settings moved to team-b and kept its UID."
exit 0
