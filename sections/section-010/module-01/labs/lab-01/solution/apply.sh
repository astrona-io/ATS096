#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays empty for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl apply -f - <<'YAML'
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-staging
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
  postBuild:
    substitute:
      environment: staging
      message: staging
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-production
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-production
  sourceRef:
    kind: GitRepository
    name: fleet
  patches:
    - patch: |
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: podinfo
        spec:
          replicas: 2
      target:
        kind: Deployment
        name: podinfo
  postBuild:
    substitute:
      environment: production
      message: production
YAML

flux reconcile kustomization podinfo-staging --timeout=3m
flux reconcile kustomization podinfo-production --timeout=3m
