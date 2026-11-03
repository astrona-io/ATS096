#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n flux-system patch kustomization apps-staging --type=merge \
  -p '{"spec":{"suspend":false,"interval":"5m","retryInterval":"1m","timeout":"3m"}}'
flux reconcile kustomization apps-staging --with-source --timeout=4m
