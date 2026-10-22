#!/usr/bin/env bash
# Creates the starting state for ats-096-lab-040-01.
#
# Installs podinfo in podinfo-production with a HelmRelease that has no drift
# detection, then sets the CPU request of the podinfo container to 50m by hand,
# the way the platform team tuned it. Turning on drift correction without
# losing that value is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/helm.yaml"
kubectl -n flux-system wait helmrepository/podinfo --for=condition=Ready --timeout=180s
flux reconcile helmrelease podinfo -n podinfo-production --timeout=5m
kubectl -n podinfo-production rollout status deployment/podinfo --timeout=180s

echo "[lab] Tuning the CPU request by hand..."
kubectl -n podinfo-production patch deployment podinfo --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/cpu","value":"50m"}]'
kubectl -n podinfo-production rollout status deployment/podinfo --timeout=180s

echo "[lab] Leaving the manual scale from the load test..."
kubectl -n podinfo-production scale deployment podinfo --replicas=6

echo "[lab] Starting state ready."
flux get helmreleases -n podinfo-production || true
echo "[lab] Production does not correct drift yet. Changing that is the task."
