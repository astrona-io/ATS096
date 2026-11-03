#!/usr/bin/env bash
# Starting state for ats-096-lab-030-03.
#
# The repository already holds charts/hello (seeded from manifests/repo).
# The ConfigMap hello-message exists in podinfo-staging. No HelmRelease exists
# yet; creating it is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n podinfo-staging delete helmrelease --all --ignore-not-found
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: hello-message
  namespace: podinfo-staging
data:
  message: from-configmap
YAML

echo "[lab] Starting state ready."
echo "[lab] gitops/fleet holds charts/hello and the ConfigMap hello-message exists. Installing hello is the task."
