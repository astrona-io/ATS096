#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays untouched for the student.
# Taken from solution.md - if one changes, change the other.
# It patches the live Flux Kustomization, because the Flux Kustomization
# object is not stored in Git in this lab.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch kustomization podinfo-secure --type merge \
  -p '{"spec":{"decryption":{"provider":"sops","secretRef":{"name":"sops-age"}}}}'

flux reconcile source git fleet --timeout=3m
flux reconcile kustomization podinfo-secure --timeout=3m
kubectl -n podinfo-staging rollout status deployment/podinfo --timeout=3m
