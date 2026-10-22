#!/usr/bin/env bash
# PASS when infrastructure, apps-staging and apps-production are all Ready, redis
# is ready, and podinfo answers staging and production in its two namespaces.
set -uo pipefail

for name in infrastructure apps-staging apps-production; do
  READY=""
  for _ in $(seq 1 60); do
    READY="$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)"
    [ "$READY" = "True" ] && break
    sleep 3
  done
  if [ "$READY" != "True" ]; then
    echo "FAIL: $name is not Ready: $(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].message}' 2>/dev/null)"
    exit 1
  fi
done

if [ "$(kubectl -n infrastructure get deployment redis -o jsonpath='{.status.readyReplicas}' 2>/dev/null)" != "1" ]; then
  echo "FAIL: the Deployment redis in infrastructure is not ready."
  exit 1
fi

for environment in staging production; do
  MESSAGE=""
  for _ in $(seq 1 20); do
    MESSAGE="$(kubectl -n gitea exec deploy/tester -- sh -c "curl -s --max-time 5 http://podinfo.podinfo-$environment:9898 | jq -r .message" 2>/dev/null)"
    [ "$MESSAGE" = "$environment" ] && break
    sleep 3
  done
  if [ "$MESSAGE" != "$environment" ]; then
    echo "FAIL: podinfo in podinfo-$environment answers '$MESSAGE'; it must answer $environment."
    exit 1
  fi
done

echo "PASS: all three stages are Ready, redis runs, and podinfo answers staging and production."
exit 0
