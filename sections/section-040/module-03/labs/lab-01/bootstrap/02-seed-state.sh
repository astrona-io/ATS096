#!/usr/bin/env bash
# Starting state for ats-096-lab-040-03.
#
# Two Flux Kustomization objects, team-a and team-b. team-a applies the
# ConfigMap shared-settings. The UID of that ConfigMap is saved so that the
# grading can tell a moved object from a recreated one.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl apply -f "$MANIFESTS/start.yaml"
flux reconcile kustomization team-a --with-source --timeout=5m
flux reconcile kustomization team-b --with-source --timeout=5m

uid="$(kubectl -n podinfo-staging get configmap shared-settings -o jsonpath='{.metadata.uid}')"
kubectl -n flux-system create configmap lab-uid-record --from-literal=uid="$uid" --dry-run=client -o yaml | kubectl apply -f -

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] team-a applies shared-settings. Moving it to team-b without recreating it is the task."
