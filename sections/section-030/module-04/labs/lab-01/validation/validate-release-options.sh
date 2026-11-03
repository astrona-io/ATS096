#!/usr/bin/env bash
# PASS when the HelmRelease podinfo has the requested namespaces, name and history.
set -uo pipefail

ns=podinfo-staging
get() { kubectl -n "$ns" get helmrelease podinfo -o jsonpath="$1" 2>/dev/null; }

if [ -z "$(get '{.metadata.name}')" ]; then
  echo "FAIL: no HelmRelease podinfo in $ns."
  exit 1
fi
check() {
  local got
  got="$(get "$1")"
  if [ "$got" != "$2" ]; then
    echo "FAIL: $3 must be '$2'. It is: '$got'"
    exit 1
  fi
}
check '{.spec.releaseName}' podinfo "spec.releaseName"
check '{.spec.targetNamespace}' podinfo-app "spec.targetNamespace"
check '{.spec.storageNamespace}' podinfo-staging "spec.storageNamespace"
check '{.spec.install.createNamespace}' true "spec.install.createNamespace"
check '{.spec.maxHistory}' 3 "spec.maxHistory"
echo "PASS: podinfo has releaseName, targetNamespace, storageNamespace, createNamespace and maxHistory 3."
exit 0
