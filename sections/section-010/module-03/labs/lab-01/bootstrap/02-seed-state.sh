#!/usr/bin/env bash
# Starting state for ats-096-lab-010-03.
#
# The Flux Kustomization podinfo-staging is applied with a path that has a
# typo. The overlay in Git has a second fault: its replacement reads the key
# data.msg, and the ConfigMap has the key message. This script only applies
# the Flux Kustomization; it never waits for it to become Ready, because it
# cannot. Finding and fixing both faults is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/start.yaml"

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] podinfo-staging does not become Ready yet. Finding out why is the task."
