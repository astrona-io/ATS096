#!/usr/bin/env bash
# PASS when Git holds shared-settings under apps/team-b and not under apps/team-a.
set -uo pipefail

raw() {
  kubectl -n gitea exec deploy/tester -- curl -sS -u gitops:gitops-password \
    "http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/contents/$1?ref=main" 2>/dev/null
}
a="$(raw apps/team-a)"
b="$(raw apps/team-b)"
if printf '%s' "$a" | command grep -q 'shared-settings'; then
  echo "FAIL: apps/team-a in Git still mentions shared-settings."
  exit 1
fi
if printf '%s' "$a" | command grep -q 'settings.yaml'; then
  echo "FAIL: apps/team-a still has settings.yaml."
  exit 1
fi
files="$(raw apps/team-b/settings.yaml)"
if ! printf '%s' "$files" | command grep -Eq '"name": *"settings.yaml"'; then
  echo "FAIL: apps/team-b/settings.yaml is not in Git."
  exit 1
fi
kust="$(kubectl -n gitea exec deploy/tester -- curl -fsS -u gitops:gitops-password \
  'http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/raw/apps/team-b/kustomization.yaml?ref=main' 2>/dev/null)"
if ! printf '%s' "$kust" | command grep -q 'settings.yaml'; then
  echo "FAIL: apps/team-b/kustomization.yaml does not list settings.yaml."
  exit 1
fi
echo "PASS: Git holds shared-settings under apps/team-b only."
exit 0
