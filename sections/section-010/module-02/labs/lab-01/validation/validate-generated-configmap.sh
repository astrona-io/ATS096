#!/usr/bin/env bash
# PASS when the Deployment podinfo in podinfo-staging reads a generated
# ConfigMap (name podinfo-config-<hash>) that Flux applied, and exactly one
# such ConfigMap is left in the namespace.
set -uo pipefail

NAMESPACE="podinfo-staging"

CONFIG_NAME=""
for _ in $(seq 1 40); do
  CONFIG_NAME="$(kubectl -n "$NAMESPACE" get deployment podinfo \
    -o jsonpath='{.spec.template.spec.containers[0].envFrom[0].configMapRef.name}' 2>/dev/null)"
  [[ "$CONFIG_NAME" =~ ^podinfo-config-[a-z0-9]+$ ]] && break
  sleep 3
done
if [[ ! "$CONFIG_NAME" =~ ^podinfo-config-[a-z0-9]+$ ]]; then
  echo "FAIL: the Deployment podinfo reads the ConfigMap '${CONFIG_NAME}'; it must read a generated name such as podinfo-config-<hash>."
  exit 1
fi

if ! kubectl -n "$NAMESPACE" get configmap "$CONFIG_NAME" >/dev/null 2>&1; then
  echo "FAIL: the ConfigMap $CONFIG_NAME does not exist in $NAMESPACE."
  exit 1
fi

INVENTORY="$(kubectl -n flux-system get kustomization podinfo-staging \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}' 2>/dev/null)"
if [[ "$INVENTORY" != *"${NAMESPACE}_${CONFIG_NAME}_"*ConfigMap* ]]; then
  echo "FAIL: the ConfigMap $CONFIG_NAME is not in the inventory of podinfo-staging. Flux must apply it, not kubectl."
  exit 1
fi

COUNT="$(kubectl -n "$NAMESPACE" get configmap -o name 2>/dev/null | command grep -c '^configmap/podinfo-config')"
if [ "$COUNT" != "1" ]; then
  echo "FAIL: $COUNT ConfigMaps named podinfo-config* exist in $NAMESPACE; exactly one must be left (the plain ConfigMap must be gone)."
  exit 1
fi

echo "PASS: the Deployment reads the generated ConfigMap $CONFIG_NAME and it is the only one left."
exit 0
