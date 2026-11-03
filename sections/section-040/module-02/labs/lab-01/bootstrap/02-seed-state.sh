#!/usr/bin/env bash
# Starting state for ats-096-lab-040-02.
#
# Applies the Flux Kustomization podinfo-staging, which installs podinfo with
# replicas: 1 from Git. Letting another writer own the replicas is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/start.yaml"
flux reconcile kustomization podinfo-staging --with-source --timeout=5m
kubectl -n podinfo-staging rollout status deployment/podinfo --timeout=180s

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] Git sets replicas: 1 and Flux owns the field. Handing it to an autoscaler is the task."
