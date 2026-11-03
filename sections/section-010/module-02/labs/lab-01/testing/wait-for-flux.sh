#!/usr/bin/env bash
# Runs before the reference solution is applied.
#
# `astrona test` bootstraps and applies in one go. Wait until Gitea answers
# and every Flux controller is available, so a reconcile request is not lost.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

kubectl -n gitea rollout status deployment/gitea --timeout=300s
kubectl -n flux-system wait deployment --all --for=condition=Available --timeout=300s
for _ in $(seq 1 60); do
  flux check >/dev/null 2>&1 && exit 0
  sleep 3
done
echo "Flux did not pass flux check in time." >&2
exit 1
