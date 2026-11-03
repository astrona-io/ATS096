#!/usr/bin/env bash
# Starting state for ats-096-lab-020-02.
#
# Installs the Widget definition. The repository already holds apps/widget
# (seeded from manifests/repo). No Flux Kustomization exists yet.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl -n flux-system delete kustomization --all --ignore-not-found
kubectl apply -f "$MANIFESTS/crd-widget.yaml"
kubectl wait --for=condition=Established crd/widgets.demo.astrona.io --timeout=60s

echo "[lab] Starting state ready."
echo "[lab] The Widget definition exists and gitops/fleet holds apps/widget. Gating the widget is the task."
