#!/usr/bin/env bash
# Creates the starting state for ats-096-capstone-040.
#
#   1. Staging is applied once with pruning off, from a base that still has
#      legacy-configmap.yaml and the annotation kustomize.toolkit.fluxcd.io/ssa:
#      IfNotPresent on the Deployment.
#   2. legacy-configmap.yaml is removed from Git; with pruning off, the
#      ConfigMap stays behind and drops off the inventory.
#   3. The staging message is changed to "staging v2" in the Flux object; the
#      IfNotPresent annotation keeps the old Deployment, so it never arrives.
#   4. Production is installed with drift detection in warn mode and scaled by
#      hand to 4 replicas.
# Nothing is fixed here; finding and fixing the faults is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"
GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/contents"

file_sha() {
  # file_sha PATH: prints the blob sha of a file on main, from the tester pod.
  kubectl -n gitea exec deploy/tester -- sh -c \
    "curl -fsS -u '$GIT_USER:$GIT_PASSWORD' '$API/$1?ref=main' | jq -r .sha"
}

put_file() {
  # put_file REPO_PATH LOCAL_CONTENT MESSAGE: replaces one file on main.
  local sha content
  sha="$(file_sha "$1")"
  content="$(printf '%s' "$2" | base64 | tr -d '\n')"
  printf '{"content":"%s","sha":"%s","message":"%s","branch":"main"}' "$content" "$sha" "$3" \
    | kubectl -n gitea exec -i deploy/tester -- curl -fsS -u "$GIT_USER:$GIT_PASSWORD" \
        -X PUT -H 'Content-Type: application/json' --data-binary @- "$API/$1" >/dev/null
}

delete_file() {
  # delete_file REPO_PATH MESSAGE: deletes one file on main.
  local sha
  sha="$(file_sha "$1")"
  printf '{"sha":"%s","message":"%s","branch":"main"}' "$sha" "$2" \
    | kubectl -n gitea exec -i deploy/tester -- curl -fsS -u "$GIT_USER:$GIT_PASSWORD" \
        -X DELETE -H 'Content-Type: application/json' --data-binary @- "$API/$1" >/dev/null
}

echo "[lab] Applying staging with pruning off..."
kubectl apply -f "$MANIFESTS/staging.yaml"
flux reconcile kustomization podinfo-staging --timeout=4m

echo "[lab] Removing legacy-configmap.yaml from Git..."
delete_file apps/podinfo/base/legacy-configmap.yaml "Remove legacy settings"
put_file apps/podinfo/base/kustomization.yaml 'apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - deployment.yaml
  - service.yaml
' "Stop listing legacy settings"
flux reconcile kustomization podinfo-staging --with-source --timeout=4m

echo "[lab] Changing the staging message..."
kubectl -n flux-system patch kustomization podinfo-staging --type=merge \
  -p '{"spec":{"postBuild":{"substitute":{"environment":"staging","message":"staging v2"}}}}'
flux reconcile kustomization podinfo-staging --timeout=4m

echo "[lab] Installing production with drift detection in warn mode..."
kubectl apply -f "$MANIFESTS/helm.yaml"
kubectl -n flux-system wait helmrepository/podinfo --for=condition=Ready --timeout=180s
flux reconcile helmrelease podinfo -n podinfo-production --timeout=5m
kubectl -n podinfo-production scale deployment podinfo --replicas=4

echo "[lab] Starting state ready."
flux get kustomizations || true
flux get helmreleases -A || true
echo "[lab] Neither environment matches Git. Finding out why is the task."
