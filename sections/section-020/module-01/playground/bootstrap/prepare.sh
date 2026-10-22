#!/usr/bin/env bash
# OS prep for the "Order And Gate Deployments With dependsOn And Health Checks" playground (`ats-096-playground-020-01`).
#
# Environment preparation only. There is no task and no grading. This script:
#   1. puts the Flux CLI (pinned) on the PATH,
#   2. starts Gitea and makes gitea.localtest.me resolve to it inside the cluster,
#   3. creates the Gitea user gitops and the repository gitops/fleet, and seeds it,
#   4. installs the Flux controllers with `flux install`,
#   5. connects Flux to the repository (Secret fleet-auth, GitRepository fleet)
#      and creates the namespaces podinfo-staging and podinfo-production,
#   6. applies the module's starting Flux objects, if it has any.
set -euo pipefail

PLAYGROUND_NAME="ats-096-playground-020-01"
FLUX_VERSION="2.9.6"
GIT_HOST="gitea.localtest.me"
GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
REPO="fleet"

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
mkdir -p "$BIN_DIR"
export PATH="$BIN_DIR:$PATH"

# Pin the version rather than accepting whatever flux happens to be on the
# machine: the CLI installs controllers of its own version.
have_version=""
command -v flux >/dev/null 2>&1 && \
  have_version=$(flux version --client 2>/dev/null | awk '/flux:/{print $2}' | sed 's/^v//')
if [ "$have_version" != "$FLUX_VERSION" ]; then
  OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
  ARCH="$(uname -m)"
  case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
  WORK="$(mktemp -d)"
  trap 'rm -rf "$WORK"' EXIT
  echo "[playground] Downloading Flux CLI ${FLUX_VERSION} (${OS}/${ARCH})..."
  curl -fsSL "https://github.com/fluxcd/flux2/releases/download/v${FLUX_VERSION}/flux_${FLUX_VERSION}_${OS}_${ARCH}.tar.gz" \
    | tar -xz -C "$WORK" flux
  install -m 0755 "$WORK/flux" "$BIN_DIR/flux"
fi
flux version --client

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="$SCRIPT_DIR/../manifests"
MANIFESTS="$MANIFEST_DIR"

echo "[playground] Applying Gitea and the tester pod..."
kubectl apply -f "$MANIFESTS/lab-start.yaml"
kubectl -n gitea rollout status deployment/gitea --timeout=300s
kubectl -n gitea rollout status deployment/tester --timeout=300s

# One Git address for the learner's machine and the cluster. The answer is
# rewritten back to the asked name: Go programs such as the Flux controllers
# ignore DNS answers whose name differs from the question.
if ! kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' | grep -q "$GIT_HOST"; then
  echo "[playground] Adding the CoreDNS rewrite for ${GIT_HOST}..."
  COREFILE="$(kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}' \
    | awk '/^[[:space:]]*kubernetes / && !done {
        print "    rewrite stop {"
        print "        name regex gitea\\.localtest\\.me gitea-http.gitea.svc.cluster.local"
        print "        answer name gitea-http\\.gitea\\.svc\\.cluster\\.local gitea.localtest.me"
        print "    }"
        done=1
      } {print}')"
  kubectl -n kube-system create configmap coredns --from-literal=Corefile="$COREFILE" \
    --dry-run=client -o yaml | kubectl apply -f -
  kubectl -n kube-system rollout restart deployment/coredns
  kubectl -n kube-system rollout status deployment/coredns --timeout=120s
fi

gitea_api() {
  # gitea_api METHOD PATH [JSON]: calls the Gitea API from the tester pod.
  local method="$1" path="$2" body="${3:-}"
  if [ -n "$body" ]; then
    printf '%s' "$body" | kubectl -n gitea exec -i deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" -H 'Content-Type: application/json' \
      --data-binary @- "http://gitea-http.gitea:3000/api/v1$path"
  else
    kubectl -n gitea exec deploy/tester -- \
      curl -fsS -u "$GIT_USER:$GIT_PASSWORD" -X "$method" "http://gitea-http.gitea:3000/api/v1$path"
  fi
}

seed_file() {
  # seed_file LOCAL_FILE REPO_PATH: commits one file to gitops/fleet on main.
  local content
  content="$(base64 < "$1" | tr -d '\n')"
  gitea_api POST "/repos/$GIT_USER/$REPO/contents/$2" \
    "{\"content\":\"$content\",\"message\":\"Add $2\",\"branch\":\"main\"}" >/dev/null
}

echo "[playground] Creating the Gitea user ${GIT_USER} and the repository ${GIT_USER}/${REPO}..."
for _ in $(seq 1 30); do
  kubectl -n gitea exec deploy/gitea -- gitea admin user create \
    --username "$GIT_USER" --password "$GIT_PASSWORD" --email gitops@example.com \
    --admin --must-change-password=false >/dev/null 2>&1 && break
  gitea_api GET "/user" >/dev/null 2>&1 && break
  sleep 2
done
gitea_api GET "/repos/$GIT_USER/$REPO" >/dev/null 2>&1 || \
  gitea_api POST "/user/repos" "{\"name\":\"$REPO\",\"auto_init\":true,\"default_branch\":\"main\",\"private\":true}" >/dev/null

echo "[playground] Seeding the repository..."
if ! gitea_api GET "/repos/$GIT_USER/$REPO/contents/apps/podinfo/base/kustomization.yaml" >/dev/null 2>&1; then
  (cd "$MANIFESTS/repo" && find . -type f | sed 's|^\./||' | sort) | while read -r file; do
    seed_file "$MANIFESTS/repo/$file" "$file"
  done
fi

echo "[playground] Installing the Flux controllers..."
flux install
flux check

echo "[playground] Connecting Flux to the repository..."
flux create secret git fleet-auth \
  --url=http://gitea.localtest.me:3000/gitops/fleet.git \
  --username="$GIT_USER" \
  --password="$GIT_PASSWORD"
kubectl apply -f "$MANIFESTS/namespaces.yaml"
kubectl apply -f "$MANIFESTS/source.yaml"
kubectl -n flux-system wait gitrepository/fleet --for=condition=Ready --timeout=180s

# Starting Flux objects for this playground, if the module needs any.
if [ -f "$MANIFEST_DIR/start.yaml" ]; then
  echo "[playground] Applying the starting Flux objects..."
  kubectl apply -f "$MANIFEST_DIR/start.yaml"
fi

echo "[playground] ${PLAYGROUND_NAME}: Git server, Flux and the fleet source ready."
echo "[playground] Start the port-forward in a second terminal before you use git:"
echo "  kubectl -n gitea port-forward svc/gitea-http 3000:3000"
