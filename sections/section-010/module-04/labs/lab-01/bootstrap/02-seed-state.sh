#!/usr/bin/env bash
# Starting state for ats-096-lab-010-04.
#
# This script installs age and sops, creates an age key pair, stores the
# private key as the Secret sops-age in flux-system, encrypts the Secret
# podinfo-credentials with sops, commits it to gitops/fleet through the
# Gitea API, and applies the Flux Kustomization podinfo-secure. That
# Kustomization has no decryption block, so it cannot become Ready. Adding
# the decryption block is the task.
set -euo pipefail

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFESTS="$SCRIPT_DIR/../manifests"

AGE_VERSION="1.2.1"
SOPS_VERSION="3.9.4"
if ! command -v age-keygen >/dev/null 2>&1 || ! command -v sops >/dev/null 2>&1; then
  TOOL_OS="$(uname -s | tr "[:upper:]" "[:lower:]")"
  TOOL_ARCH="$(uname -m)"
  case "$TOOL_ARCH" in x86_64) TOOL_ARCH=amd64 ;; aarch64|arm64) TOOL_ARCH=arm64 ;; esac
  TOOL_WORK="$(mktemp -d)"
  echo "[lab] Downloading age ${AGE_VERSION} and sops ${SOPS_VERSION} (${TOOL_OS}/${TOOL_ARCH})..."
  curl -fsSL "https://github.com/FiloSottile/age/releases/download/v${AGE_VERSION}/age-v${AGE_VERSION}-${TOOL_OS}-${TOOL_ARCH}.tar.gz" \
    | tar -xz -C "$TOOL_WORK"
  install -m 0755 "$TOOL_WORK/age/age" "$BIN_DIR/age"
  install -m 0755 "$TOOL_WORK/age/age-keygen" "$BIN_DIR/age-keygen"
  curl -fsSL -o "$TOOL_WORK/sops" "https://github.com/getsops/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.${TOOL_OS}.${TOOL_ARCH}"
  install -m 0755 "$TOOL_WORK/sops" "$BIN_DIR/sops"
  rm -rf "$TOOL_WORK"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# 1. Age key pair, and the private key as a Secret in flux-system.
age-keygen -o "$WORK/age.agekey" >/dev/null 2>&1
PUBLIC_KEY="$(age-keygen -y "$WORK/age.agekey")"
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$WORK/age.agekey" \
  --dry-run=client -o yaml | kubectl apply -f -

# 2. Encrypt only the data of the Secret podinfo-credentials.
cat > "$WORK/secret.yaml" <<'YAML'
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-credentials
type: Opaque
stringData:
  message: sealed-by-sops
YAML
sops --encrypt --age "$PUBLIC_KEY" --encrypted-regex '^(data|stringData)$' \
  "$WORK/secret.yaml" > "$WORK/secret.sops.yaml"

# 3. Commit the encrypted file through the Gitea API from the tester pod.
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/contents"
ENCODED="$(base64 < "$WORK/secret.sops.yaml" | tr -d '\n')"
EXISTING="$(kubectl -n gitea exec deploy/tester -- \
  curl -s -u gitops:gitops-password "$API/apps/podinfo/base/secret.sops.yaml" | kubectl -n gitea exec -i deploy/tester -- jq -r '.sha // empty')"
if [ -n "$EXISTING" ]; then
  BODY="$(printf '{"content":"%s","sha":"%s","message":"Add encrypted podinfo-credentials","branch":"main"}' "$ENCODED" "$EXISTING")"
  METHOD=PUT
else
  BODY="$(printf '{"content":"%s","message":"Add encrypted podinfo-credentials","branch":"main"}' "$ENCODED")"
  METHOD=POST
fi
printf '%s' "$BODY" | kubectl -n gitea exec -i deploy/tester -- \
  curl -fsS -u gitops:gitops-password -X "$METHOD" -H 'Content-Type: application/json' \
  --data-binary @- "$API/apps/podinfo/base/secret.sops.yaml" >/dev/null

# 4. Apply the Flux Kustomization that cannot decrypt yet.
flux reconcile source git fleet --timeout=3m
kubectl apply -f "$MANIFESTS/start.yaml"

echo "[lab] Starting state ready."
flux get kustomizations || true
echo "[lab] podinfo-secure cannot apply the encrypted Secret yet. Fixing that is the task."
