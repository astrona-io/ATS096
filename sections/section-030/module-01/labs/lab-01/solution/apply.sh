#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays empty for the student.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

good_values() {
  # good_values NAMESPACE REPLICAS MESSAGE: prints the ConfigMap podinfo-values.
  cat <<YAML
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-values
  namespace: $1
data:
  values.yaml: |
    replicaCount: $2
    ui:
      message: $3
YAML
}

good_values podinfo-staging 1 staging | kubectl apply -f -
good_values podinfo-production 2 production | kubectl apply -f -

kubectl apply -f - <<'YAML'
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo-staging
spec:
  interval: 10m
  releaseName: podinfo
  chart:
    spec:
      chart: podinfo
      version: 6.15.0
      sourceRef:
        kind: HelmRepository
        name: podinfo
        namespace: flux-system
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-values
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo-production
spec:
  interval: 10m
  releaseName: podinfo
  timeout: 1m
  chart:
    spec:
      chart: podinfo
      version: 6.15.0
      sourceRef:
        kind: HelmRepository
        name: podinfo
        namespace: flux-system
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-values
  upgrade:
    remediation:
      retries: 1
      strategy: rollback
YAML

flux reconcile helmrelease podinfo -n podinfo-staging --timeout=5m
flux reconcile helmrelease podinfo -n podinfo-production --timeout=5m

# The bad upgrade: a tag that does not exist. The reconcile is expected to fail.
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-values
  namespace: podinfo-production
data:
  values.yaml: |
    replicaCount: 2
    ui:
      message: production
    image:
      tag: 0.0.0-missing
YAML
flux reconcile helmrelease podinfo -n podinfo-production --timeout=8m || true

for _ in $(seq 1 60); do
  [ -n "$(kubectl -n podinfo-production get secrets -l owner=helm,name=podinfo,status=failed -o name 2>/dev/null)" ] && break
  sleep 5
done

# The fix: the good values again.
good_values podinfo-production 2 production | kubectl apply -f -
flux reconcile helmrelease podinfo -n podinfo-production --timeout=5m
