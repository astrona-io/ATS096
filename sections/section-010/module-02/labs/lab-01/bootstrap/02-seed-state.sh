#!/usr/bin/env bash
# Starting state for ats-096-lab-010-02.
#
# The repository holds the base and the staging overlay, and the overlay
# lists a plain ConfigMap file. This script applies the Flux Kustomization
# podinfo-staging and waits until it is Ready. The task changes the overlay
# in Git so that a new message rolls the pods by itself.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/start.yaml"
kubectl -n flux-system wait kustomization/podinfo-staging --for=condition=Ready --timeout=300s

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] The staging overlay uses a plain ConfigMap. Making a message change roll the pods is the task."
