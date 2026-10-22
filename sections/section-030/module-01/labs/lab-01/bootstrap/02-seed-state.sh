#!/usr/bin/env bash
# Creates the starting state for ats-096-lab-030-01.
#
# Applies the HelmRepository podinfo and waits until source-controller has
# fetched its index. No HelmRelease and no values ConfigMap exist; creating
# them is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/helmrepository.yaml"
kubectl -n flux-system wait helmrepository/podinfo --for=condition=Ready --timeout=180s

echo "[lab] Starting state ready."
flux get sources helm || true
echo "[lab] The chart repository is ready. Installing podinfo into both environments is the task."
