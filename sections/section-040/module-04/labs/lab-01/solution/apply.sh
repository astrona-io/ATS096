#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n podinfo-production patch helmrelease podinfo --type=merge -p '{
  "spec": {
    "driftDetection": {
      "mode": "enabled",
      "ignore": [
        {"paths": ["/spec/replicas"], "target": {"kind": "Deployment"}}
      ]
    }
  }
}'
flux reconcile helmrelease podinfo -n podinfo-production --timeout=5m
