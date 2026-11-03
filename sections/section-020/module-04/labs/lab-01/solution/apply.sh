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
  name: chart
  namespace: flux-system
spec:
  interval: 10m
  retryInterval: 1m
  path: ./infrastructure/podinfo-chart
  prune: true
  wait: true
  timeout: 5m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: consumer
  namespace: flux-system
spec:
  interval: 10m
  retryInterval: 1m
  path: ./apps/consumer
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-staging
  dependsOn:
    - name: chart
  sourceRef:
    kind: GitRepository
    name: fleet
YAML

flux reconcile kustomization chart --timeout=6m
flux reconcile kustomization consumer --timeout=3m
