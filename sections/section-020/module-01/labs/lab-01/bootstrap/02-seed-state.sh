#!/usr/bin/env bash
# Starting state for ats-096-lab-020-01.
#
# The task builds the pipeline from an empty start: the fleet source is Ready
# and both podinfo namespaces exist (created by 01-install-git-and-flux.sh).
# This script only makes sure no Flux Kustomization exists yet.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system delete kustomization --all --ignore-not-found

echo "[lab] Starting state ready."
flux get sources git || true
echo "[lab] No Flux Kustomization exists yet. Building the pipeline is the task."
