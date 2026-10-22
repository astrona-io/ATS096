#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n podinfo-staging patch ocirepository podinfo-chart --type=merge \
  -p '{"spec":{"ref":{"tag":"6.15.0"}}}'
kubectl -n podinfo-production patch helmrelease podinfo --type=json \
  -p '[{"op":"add","path":"/spec/chart/spec/sourceRef/namespace","value":"flux-system"},
       {"op":"add","path":"/spec/valuesFrom/0/valuesKey","value":"values.yml"}]'

flux reconcile source oci podinfo-chart -n podinfo-staging --timeout=3m
flux reconcile helmrelease podinfo -n podinfo-staging --timeout=5m
flux reconcile helmrelease podinfo -n podinfo-production --timeout=5m
