#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch kustomization podinfo-staging --type=merge \
  -p '{"spec":{"targetNamespace":"podinfo-staging"}}'
kubectl -n flux-system patch kustomization podinfo-production --type=json \
  -p '[{"op":"replace","path":"/spec/postBuild/substituteFrom/0/name","value":"podinfo-prod-vars"},
       {"op":"replace","path":"/spec/patches/0/target/name","value":"podinfo"}]'

flux reconcile kustomization podinfo-staging --timeout=3m
flux reconcile kustomization podinfo-production --timeout=3m
