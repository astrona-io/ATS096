#!/usr/bin/env bash
# Creates the starting state for ats-096-capstone-030.
#
# Applies two HelmReleases, their sources and a values Secret, with three
# independent faults (see manifests/helm.yaml). Nothing is fixed here; finding
# and fixing the faults is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/helm.yaml"
kubectl -n flux-system wait helmrepository/podinfo --for=condition=Ready --timeout=180s || true

echo "[lab] Starting state ready."
flux get helmreleases -A || true
echo "[lab] Neither release installs. Finding out why is the task."
