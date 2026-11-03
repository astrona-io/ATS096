#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl apply -f - <<'YAML'
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: widgets
  namespace: flux-system
spec:
  interval: 10m
  retryInterval: 30s
  path: ./apps/widget
  prune: true
  wait: false
  timeout: 1m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
  healthChecks:
    - apiVersion: demo.astrona.io/v1
      kind: Widget
      name: gauge
      namespace: podinfo-staging
  healthCheckExprs:
    - apiVersion: demo.astrona.io/v1
      kind: Widget
      inProgress: has(status.phase) && status.phase == 'Starting'
      failed: has(status.phase) && status.phase == 'Failed'
      current: has(status.phase) && status.phase == 'Running'
YAML

for _ in $(seq 1 30); do
  kubectl -n podinfo-staging get widget gauge >/dev/null 2>&1 && break
  flux reconcile source git fleet >/dev/null 2>&1 || true
  flux reconcile kustomization widgets --timeout=20s >/dev/null 2>&1 || true
  sleep 2
done
kubectl -n podinfo-staging patch widget gauge --subresource=status --type=merge -p '{"status":{"phase":"Running"}}'
flux reconcile kustomization widgets --timeout=2m
