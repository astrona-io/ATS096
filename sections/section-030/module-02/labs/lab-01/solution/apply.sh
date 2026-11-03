#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl apply -f - <<'YAML'
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: hello
  namespace: podinfo-staging
spec:
  interval: 10m
  chart:
    spec:
      chart: ./charts/hello
      reconcileStrategy: Revision
      sourceRef:
        kind: GitRepository
        name: fleet
        namespace: flux-system
      valuesFiles:
        - values.yaml
        - values-staging.yaml
YAML

flux reconcile helmrelease hello -n podinfo-staging --with-source --timeout=5m
