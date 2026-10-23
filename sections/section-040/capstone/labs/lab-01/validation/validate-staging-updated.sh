#!/usr/bin/env bash
# PASS when the ssa annotation is gone from the Deployment in Git, the Flux
# Kustomization still asks for "staging v2", and podinfo answers with it.
set -uo pipefail
# grep -q stops reading at the first match; under pipefail the command
# writing into the pipe then fails with SIGPIPE and a match looks like a
# failure. This wrapper reads all input instead and keeps grep's exit status.
grep() {
  local arg quiet=0 args=()
  for arg in "$@"; do
    case "$arg" in
      --quiet|--silent) quiet=1 ;;
      --*) args+=("$arg") ;;
      -*q*) quiet=1; [ "$arg" = "-q" ] || args+=("${arg//q/}") ;;
      *) args+=("$arg") ;;
    esac
  done
  if [ "$quiet" = 1 ]; then command grep "${args[@]}" >/dev/null; else command grep "$@"; fi
}

RAW="$(kubectl -n gitea exec deploy/tester -- curl -fsS -u gitops:gitops-password \
  'http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/raw/apps/podinfo/base/deployment.yaml?ref=main' 2>/dev/null)"
if [ -z "$RAW" ]; then
  echo "FAIL: could not read apps/podinfo/base/deployment.yaml from Git."
  exit 1
fi
if printf '%s' "$RAW" | grep -q 'kustomize.toolkit.fluxcd.io/ssa'; then
  echo "FAIL: apps/podinfo/base/deployment.yaml in Git still carries the annotation kustomize.toolkit.fluxcd.io/ssa."
  exit 1
fi

WANTED="$(kubectl -n flux-system get kustomization podinfo-staging -o jsonpath='{.spec.postBuild.substitute.message}' 2>/dev/null)"
if [ "$WANTED" != "staging v2" ]; then
  echo "FAIL: the Flux Kustomization podinfo-staging asks for the message '$WANTED'; leave it at 'staging v2'."
  exit 1
fi

MESSAGE=""
for _ in $(seq 1 30); do
  MESSAGE="$(kubectl -n gitea exec deploy/tester -- sh -c 'curl -s --max-time 5 http://podinfo.podinfo-staging:9898 | jq -r .message' 2>/dev/null)"
  [ "$MESSAGE" = "staging v2" ] && break
  sleep 3
done
if [ "$MESSAGE" != "staging v2" ]; then
  echo "FAIL: podinfo in podinfo-staging answers '$MESSAGE'; it must answer 'staging v2'."
  exit 1
fi

echo "PASS: the ssa annotation is gone from Git, and staging answers staging v2."
exit 0
