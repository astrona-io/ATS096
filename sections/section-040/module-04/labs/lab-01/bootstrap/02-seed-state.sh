#!/usr/bin/env bash
# Creates the starting state for ats-096-lab-040-04.
#
# Installs podinfo in podinfo-production with a HelmRelease that corrects drift
# everywhere (driftDetection.mode: enabled, no ignore rule). A horizontal
# autoscaler would change spec.replicas, and helm-controller would undo it
# every time. Excluding only that field is the task.
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

echo "[lab] Starting state ready."
flux get helmreleases -n podinfo-production || true
echo "[lab] Production corrects all drift, including replicas. Changing that is the task."
