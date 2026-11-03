#!/usr/bin/env bash
# PASS when the Flux Kustomization podinfo-staging builds ./apps/podinfo/overlay
# from the source fleet into podinfo-staging, prunes, is not suspended, has no
# postBuild and no patches (the fix is in the overlay), and is Ready.
set -uo pipefail

field() { kubectl -n flux-system get kustomization podinfo-staging -o jsonpath="$1" 2>/dev/null; }

if ! kubectl -n flux-system get kustomization podinfo-staging >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization podinfo-staging does not exist in flux-system."
  exit 1
fi
[ "$(field '{.spec.path}')" = "./apps/podinfo/overlay" ] || { echo "FAIL: podinfo-staging has path '$(field '{.spec.path}')'; it must be ./apps/podinfo/overlay."; exit 1; }
[ "$(field '{.spec.sourceRef.name}')" = "fleet" ] || { echo "FAIL: podinfo-staging must use the GitRepository fleet as its source."; exit 1; }
[ "$(field '{.spec.targetNamespace}')" = "podinfo-staging" ] || { echo "FAIL: podinfo-staging must apply into the namespace podinfo-staging."; exit 1; }
[ "$(field '{.spec.prune}')" = "true" ] || { echo "FAIL: podinfo-staging must have prune: true."; exit 1; }
[ "$(field '{.spec.suspend}')" != "true" ] || { echo "FAIL: podinfo-staging is suspended."; exit 1; }
[ -z "$(field '{.spec.postBuild}')" ] || { echo "FAIL: podinfo-staging uses postBuild. The message must come from the replacement in the overlay."; exit 1; }
[ -z "$(field '{.spec.patches}')" ] || { echo "FAIL: podinfo-staging uses patches. The message must come from the replacement in the overlay."; exit 1; }

ready=""
for _ in $(seq 1 40); do
  ready="$(field '{.status.conditions[?(@.type=="Ready")].status}')"
  [ "$ready" = "True" ] && break
  sleep 3
done
if [ "$ready" != "True" ]; then
  echo "FAIL: podinfo-staging is not Ready: $(field '{.status.conditions[?(@.type=="Ready")].message}')"
  exit 1
fi

echo "PASS: podinfo-staging builds ./apps/podinfo/overlay and is Ready."
exit 0
