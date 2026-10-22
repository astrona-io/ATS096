#!/usr/bin/env bash
# Creates the starting state for ats-096-capstone-010.
#
# Applies the ConfigMap podinfo-prod-vars and two Flux Kustomizations with
# three independent faults (see manifests/overlays.yaml). Nothing is fixed
# here; finding and fixing the faults is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/vars.yaml"
kubectl apply -f "$MANIFESTS/overlays.yaml"

# Give both objects one reconciliation, so the learner starts from their errors.
flux reconcile kustomization podinfo-staging --timeout=1m >/dev/null 2>&1 || true
flux reconcile kustomization podinfo-production --timeout=1m >/dev/null 2>&1 || true

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] Staging and production do not run as intended. Finding out why is the task."
