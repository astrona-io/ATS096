#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the lab stays untouched for the student.
# Taken from solution.md - if one changes, change the other.
# It commits to gitops/fleet through the Gitea API from the tester pod,
# because the test host has no port-forward and no git credentials.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/contents"

replace_file() {
  # replace_file REPO_PATH CONTENT: replaces one file on main.
  local repo_path="$1" content="$2" sha encoded
  sha="$(kubectl -n gitea exec deploy/tester -- \
    curl -fsS -u gitops:gitops-password "$API/$repo_path" | kubectl -n gitea exec -i deploy/tester -- jq -r .sha)"
  encoded="$(printf '%s\n' "$content" | base64 | tr -d '\n')"
  printf '{"content":"%s","sha":"%s","message":"Update %s","branch":"main"}' "$encoded" "$sha" "$repo_path" \
    | kubectl -n gitea exec -i deploy/tester -- \
        curl -fsS -u gitops:gitops-password -X PUT -H 'Content-Type: application/json' \
        --data-binary @- "$API/$repo_path" >/dev/null
}

replace_file apps/podinfo/overlays/staging/kustomization.yaml 'apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: podinfo-staging
resources:
  - ../../base
configMapGenerator:
  - name: podinfo-config
    literals:
      - PODINFO_UI_MESSAGE=rolled-out'

flux reconcile source git fleet --timeout=3m
flux reconcile kustomization podinfo-staging --timeout=3m
kubectl -n podinfo-staging rollout status deployment/podinfo --timeout=3m
