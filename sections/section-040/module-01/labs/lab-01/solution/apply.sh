#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays unchanged for the student.
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
        {"paths": ["/spec/template/spec/containers/0/resources"], "target": {"kind": "Deployment"}}
      ]
    }
  }
}'
flux reconcile helmrelease podinfo -n podinfo-production --timeout=5m
