#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test`.
# Taken from solution.md - if one changes, change the other.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

WORK="$(mktemp -d)"
kubectl -n gitea port-forward svc/gitea-http 3000:3000 >/dev/null 2>&1 &
PF=$!
trap 'kill $PF 2>/dev/null; rm -rf "$WORK"' EXIT
sleep 3

git clone http://gitops:gitops-password@localhost:3000/gitops/fleet.git "$WORK/fleet"
cd "$WORK/fleet"
G="git -c user.name=lab -c user.email=lab@example.com"

# Commit 1: team-b takes the object.
cp apps/team-a/settings.yaml apps/team-b/settings.yaml
printf '  - settings.yaml\n' >> apps/team-b/kustomization.yaml
$G add -A
$G commit -m "Add shared-settings to team-b"
git push origin main
flux reconcile kustomization team-b --with-source --timeout=5m

# Commit 2: team-a lets go.
git rm apps/team-a/settings.yaml
sed -i.bak '/settings.yaml/d' apps/team-a/kustomization.yaml
rm apps/team-a/kustomization.yaml.bak
$G add -A
$G commit -m "Remove shared-settings from team-a"
git push origin main
flux reconcile kustomization team-a --with-source --timeout=5m
