#!/usr/bin/env bash
# Starting state for ats-096-lab-030-02.
#
# The repository already holds charts/hello (seeded from manifests/repo).
# No HelmRelease exists yet; creating it is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n podinfo-staging delete helmrelease --all --ignore-not-found

echo "[lab] Starting state ready."
echo "[lab] gitops/fleet holds charts/hello. Installing it with a HelmRelease is the task."
