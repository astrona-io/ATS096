#!/usr/bin/env bash
# PASS when staging answers staging, and production answers the message from
# the Secret with 2 ready replicas.
set -uo pipefail

check_environment() {
  local namespace="$1" expected="$2" replicas="$3" ready="" message=""
  for _ in $(seq 1 40); do
    ready="$(kubectl -n "$namespace" get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
    [ "$ready" = "$replicas" ] && break
    sleep 3
  done
  [ "$ready" = "$replicas" ] || { echo "FAIL: podinfo in $namespace has ${ready:-0} ready replicas; it must have $replicas."; return 1; }
  for _ in $(seq 1 20); do
    message="$(kubectl -n gitea exec deploy/tester -- sh -c "curl -s --max-time 5 http://podinfo.$namespace:9898 | jq -r .message" 2>/dev/null)"
    [ "$message" = "$expected" ] && break
    sleep 3
  done
  [ "$message" = "$expected" ] || { echo "FAIL: podinfo in $namespace answers '$message'; it must answer '$expected'."; return 1; }
}

check_environment podinfo-staging staging 1 || exit 1
check_environment podinfo-production "production from Secret" 2 || exit 1

echo "PASS: staging answers staging, production answers the message from the Secret with 2 replicas."
exit 0
