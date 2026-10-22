#!/usr/bin/env bash
# PASS when the patch of podinfo-production sets 3 replicas on the Deployment
# podinfo, and the Deployment applied by Flux runs 3 ready replicas.
set -uo pipefail

TARGET="$(kubectl -n flux-system get kustomization podinfo-production \
  -o jsonpath='{range .spec.patches[*]}{.target.kind}/{.target.name}{"\n"}{end}' 2>/dev/null)"
if ! printf '%s\n' "$TARGET" | grep -qx 'Deployment/podinfo'; then
  echo "FAIL: no patch of podinfo-production targets the Deployment podinfo. Targets found: $TARGET"
  exit 1
fi

INVENTORY="$(kubectl -n flux-system get kustomization podinfo-production \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}' 2>/dev/null)"
if ! printf '%s\n' "$INVENTORY" | grep -q '^podinfo-production_podinfo_apps_Deployment'; then
  echo "FAIL: the Deployment podinfo in podinfo-production is not in the inventory of podinfo-production."
  exit 1
fi

READY_REPLICAS=""
for _ in $(seq 1 40); do
  READY_REPLICAS="$(kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  SPEC_REPLICAS="$(kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.replicas}' 2>/dev/null)"
  [ "$READY_REPLICAS" = "3" ] && [ "$SPEC_REPLICAS" = "3" ] && break
  sleep 3
done
if [ "$READY_REPLICAS" != "3" ]; then
  echo "FAIL: podinfo in podinfo-production has ${READY_REPLICAS:-0} ready replicas; the patch must set 3."
  exit 1
fi

echo "PASS: the patch targets the Deployment podinfo, and production runs 3 ready replicas."
exit 0
