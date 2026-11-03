#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
kubectl -n gitea port-forward svc/gitea-http 3000:3000 >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null; rm -rf "$WORK"' EXIT
sleep 3

git clone http://gitops:gitops-password@localhost:3000/gitops/fleet.git "$WORK/fleet"
cd "$WORK/fleet"
sed -i.bak '/^  replicas: 1$/d' apps/podinfo/base/deployment.yaml
rm apps/podinfo/base/deployment.yaml.bak
git -c user.name=lab -c user.email=lab@example.com commit -am "Let the autoscaler own the replicas"
git push origin main

flux reconcile kustomization podinfo-staging --with-source --timeout=5m
kubectl -n podinfo-staging patch deployment podinfo --type=merge -p '{"spec":{"replicas":4}}' --field-manager=autoscaler
flux reconcile kustomization podinfo-staging --timeout=5m
