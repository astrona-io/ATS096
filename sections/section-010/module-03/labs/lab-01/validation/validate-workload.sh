#!/usr/bin/env bash
# PASS when the Deployment podinfo in podinfo-staging has 1 ready replica
# and podinfo answers with the message from-replacement.
set -uo pipefail

NAMESPACE="podinfo-staging"
EXPECTED="from-replacement"

READY_REPLICAS=""
for _ in $(seq 1 40); do
  READY_REPLICAS="$(kubectl -n "$NAMESPACE" get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ "$READY_REPLICAS" = "1" ] && break
  sleep 3
done
if [ "$READY_REPLICAS" != "1" ]; then
  echo "FAIL: podinfo in $NAMESPACE has ${READY_REPLICAS:-0} ready replicas; it must have 1."
  exit 1
fi

INVENTORY="$(kubectl -n flux-system get kustomization podinfo-staging \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}' 2>/dev/null)"
if [[ "$INVENTORY" != *"${NAMESPACE}_podinfo_apps_Deployment"* ]]; then
  echo "FAIL: the Deployment podinfo is not in the inventory of podinfo-staging. Flux must apply it, not kubectl."
  exit 1
fi

MESSAGE=""
for _ in $(seq 1 30); do
  MESSAGE="$(kubectl -n gitea exec deploy/tester -- sh -c "curl -s --max-time 5 http://podinfo.$NAMESPACE:9898 | jq -r .message" 2>/dev/null)"
  [ "$MESSAGE" = "$EXPECTED" ] && break
  sleep 3
done
if [ "$MESSAGE" != "$EXPECTED" ]; then
  echo "FAIL: podinfo in $NAMESPACE answers with the message '$MESSAGE'; it must be $EXPECTED."
  exit 1
fi

echo "PASS: podinfo in $NAMESPACE answers with the message $EXPECTED."
exit 0
