#!/usr/bin/env bash
# PASS when the Flux Kustomization podinfo-secure still builds ./apps/podinfo/base,
# prunes, is not suspended, uses sops decryption with the Secret sops-age,
# and is Ready.
set -uo pipefail

field() { kubectl -n flux-system get kustomization podinfo-secure -o jsonpath="$1" 2>/dev/null; }

if ! kubectl -n flux-system get kustomization podinfo-secure >/dev/null 2>&1; then
  echo "FAIL: the Flux Kustomization podinfo-secure does not exist in flux-system."
  exit 1
fi
[ "$(field '{.spec.path}')" = "./apps/podinfo/base" ] || { echo "FAIL: podinfo-secure has path '$(field '{.spec.path}')'; it must stay ./apps/podinfo/base."; exit 1; }
[ "$(field '{.spec.sourceRef.name}')" = "fleet" ] || { echo "FAIL: podinfo-secure must use the GitRepository fleet as its source."; exit 1; }
[ "$(field '{.spec.prune}')" = "true" ] || { echo "FAIL: podinfo-secure must have prune: true."; exit 1; }
[ "$(field '{.spec.suspend}')" != "true" ] || { echo "FAIL: podinfo-secure is suspended."; exit 1; }
[ "$(field '{.spec.decryption.provider}')" = "sops" ] || { echo "FAIL: spec.decryption.provider of podinfo-secure is '$(field '{.spec.decryption.provider}')'; it must be sops."; exit 1; }
[ "$(field '{.spec.decryption.secretRef.name}')" = "sops-age" ] || { echo "FAIL: spec.decryption.secretRef.name of podinfo-secure is '$(field '{.spec.decryption.secretRef.name}')'; it must be sops-age."; exit 1; }

ready=""
for _ in $(seq 1 40); do
  ready="$(field '{.status.conditions[?(@.type=="Ready")].status}')"
  [ "$ready" = "True" ] && break
  sleep 3
done
if [ "$ready" != "True" ]; then
  echo "FAIL: podinfo-secure is not Ready: $(field '{.status.conditions[?(@.type=="Ready")].message}')"
  exit 1
fi

echo "PASS: podinfo-secure decrypts with sops and the Secret sops-age and is Ready."
exit 0
