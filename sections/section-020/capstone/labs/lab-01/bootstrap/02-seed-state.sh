#!/usr/bin/env bash
# Creates the starting state for ats-096-capstone-020.
#
# Applies a three-stage pipeline with one fault per stage (see
# manifests/pipeline.yaml). Nothing is fixed here; finding and fixing the
# faults is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/pipeline.yaml"
flux reconcile kustomization infrastructure --timeout=1m >/dev/null 2>&1 || true

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] The pipeline delivers nothing. Finding out why is the task."
