#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch kustomization infrastructure --type=merge \
  -p '{"spec":{"path":"./infrastructure/redis"}}'
kubectl -n flux-system patch kustomization apps-staging --type=json \
  -p '[{"op":"replace","path":"/spec/healthChecks/0/name","value":"podinfo"}]'
kubectl -n flux-system patch kustomization apps-production --type=json \
  -p '[{"op":"replace","path":"/spec/dependsOn/0/name","value":"apps-staging"}]'

flux reconcile kustomization infrastructure --timeout=3m
flux reconcile kustomization apps-staging --timeout=3m
flux reconcile kustomization apps-production --timeout=3m
