#!/usr/bin/env bash
# PASS when podinfo-staging applies into podinfo-staging, is Ready, and podinfo
# there answers with the message staging.
set -uo pipefail

field() { kubectl -n flux-system get kustomization podinfo-staging -o jsonpath="$1" 2>/dev/null; }

if [ "$(field '{.spec.targetNamespace}')" != "podinfo-staging" ]; then
  echo "FAIL: podinfo-staging applies into '$(field '{.spec.targetNamespace}')'; it must apply into podinfo-staging."
  exit 1
fi
[ "$(field '{.spec.suspend}')" != "true" ] || { echo "FAIL: podinfo-staging is suspended."; exit 1; }

READY=""
for _ in $(seq 1 40); do
  READY="$(field '{.status.conditions[?(@.type=="Ready")].status}')"
  [ "$READY" = "True" ] && break
  sleep 3
done
[ "$READY" = "True" ] || { echo "FAIL: podinfo-staging is not Ready: $(field '{.status.conditions[?(@.type=="Ready")].message}')"; exit 1; }

MESSAGE=""
for _ in $(seq 1 20); do
  MESSAGE="$(kubectl -n gitea exec deploy/tester -- sh -c 'curl -s --max-time 5 http://podinfo.podinfo-staging:9898 | jq -r .message' 2>/dev/null)"
  [ "$MESSAGE" = "staging" ] && break
  sleep 3
done
[ "$MESSAGE" = "staging" ] || { echo "FAIL: podinfo in podinfo-staging answers '$MESSAGE'; it must answer staging."; exit 1; }

echo "PASS: staging is Ready in podinfo-staging and answers staging."
exit 0
