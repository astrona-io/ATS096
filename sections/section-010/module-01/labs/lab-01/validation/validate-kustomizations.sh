#!/usr/bin/env bash
# PASS when podinfo-staging and podinfo-production both build ./apps/podinfo/base
# from the source fleet into their own namespace, prune, are not suspended,
# and are Ready.
set -uo pipefail

check_kustomization() {
  local name="$1" namespace="$2" field ready=""
  if ! kubectl -n flux-system get kustomization "$name" >/dev/null 2>&1; then
    echo "FAIL: the Flux Kustomization $name does not exist in flux-system."
    return 1
  fi
  field() { kubectl -n flux-system get kustomization "$name" -o jsonpath="$1" 2>/dev/null; }
  [ "$(field '{.spec.path}')" = "./apps/podinfo/base" ] || { echo "FAIL: $name has path '$(field '{.spec.path}')'; it must be ./apps/podinfo/base."; return 1; }
  [ "$(field '{.spec.sourceRef.name}')" = "fleet" ] || { echo "FAIL: $name must use the GitRepository fleet as its source."; return 1; }
  [ "$(field '{.spec.targetNamespace}')" = "$namespace" ] || { echo "FAIL: $name must apply into the namespace $namespace."; return 1; }
  [ "$(field '{.spec.prune}')" = "true" ] || { echo "FAIL: $name must have prune: true."; return 1; }
  [ "$(field '{.spec.suspend}')" != "true" ] || { echo "FAIL: $name is suspended."; return 1; }
  for _ in $(seq 1 40); do
    ready="$(field '{.status.conditions[?(@.type=="Ready")].status}')"
    [ "$ready" = "True" ] && return 0
    sleep 3
  done
  echo "FAIL: $name is not Ready: $(field '{.status.conditions[?(@.type=="Ready")].message}')"
  return 1
}

check_kustomization podinfo-staging podinfo-staging || exit 1
check_kustomization podinfo-production podinfo-production || exit 1

echo "PASS: both Flux Kustomizations build ./apps/podinfo/base into their own namespace and are Ready."
exit 0
