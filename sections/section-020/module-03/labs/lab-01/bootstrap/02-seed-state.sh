#!/usr/bin/env bash
# Starting state for ats-096-lab-020-03.
#
# Creates the Flux Kustomization apps-staging the way an operator left it:
# suspended, with a 24 hour interval, no retryInterval and a 5 second timeout.
# Resuming and tuning it is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system delete kustomization --all --ignore-not-found
kubectl apply -f - <<'YAML'
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps-staging
  namespace: flux-system
spec:
  suspend: true
  interval: 24h
  timeout: 5s
  path: ./apps/podinfo/base
  prune: true
  wait: true
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
  postBuild:
    substitute:
      environment: staging
      message: staging
YAML

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] apps-staging is suspended with a long interval and a very short timeout. Fixing it is the task."
