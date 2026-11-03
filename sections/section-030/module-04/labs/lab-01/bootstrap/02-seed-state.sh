#!/usr/bin/env bash
# Starting state for ats-096-lab-030-04.
#
# Applies the HelmRepository podinfo in flux-system and waits until
# source-controller has fetched its index. No HelmRelease exists and the
# namespace podinfo-app does not exist; creating the release is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

kubectl -n podinfo-staging delete helmrelease --all --ignore-not-found
kubectl delete namespace podinfo-app --ignore-not-found
kubectl apply -f "$MANIFESTS/helmrepository.yaml"
kubectl -n flux-system wait helmrepository/podinfo --for=condition=Ready --timeout=180s

echo "[lab] Starting state ready."
flux get sources helm || true
echo "[lab] The chart repository is ready. Installing podinfo into podinfo-app is the task."
