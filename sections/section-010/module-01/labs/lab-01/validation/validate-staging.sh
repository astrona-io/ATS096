#!/usr/bin/env bash
# PASS when Flux applied podinfo into podinfo-staging, the Deployment runs
# 1 ready replica(s) with the label environment=staging, and podinfo
# answers with the message staging.
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

NAMESPACE="podinfo-staging"
KUSTOMIZATION="podinfo-staging"
EXPECTED="staging"
EXPECTED_REPLICAS="1"

INVENTORY="$(kubectl -n flux-system get kustomization "$KUSTOMIZATION" \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}' 2>/dev/null)"
if ! printf '%s\n' "$INVENTORY" | grep -q "^${NAMESPACE}_podinfo_apps_Deployment"; then
  echo "FAIL: the Deployment podinfo in $NAMESPACE is not in the inventory of $KUSTOMIZATION. Flux must apply it, not kubectl."
  exit 1
fi

READY_REPLICAS=""
for _ in $(seq 1 40); do
  READY_REPLICAS="$(kubectl -n "$NAMESPACE" get deployment podinfo -o jsonpath='{.status.readyReplicas}' 2>/dev/null)"
  [ "$READY_REPLICAS" = "$EXPECTED_REPLICAS" ] && break
  sleep 3
done
if [ "$READY_REPLICAS" != "$EXPECTED_REPLICAS" ]; then
  echo "FAIL: podinfo in $NAMESPACE has ${READY_REPLICAS:-0} ready replicas; it must have $EXPECTED_REPLICAS."
  exit 1
fi

LABEL="$(kubectl -n "$NAMESPACE" get deployment podinfo -o jsonpath='{.metadata.labels.environment}' 2>/dev/null)"
if [ "$LABEL" != "$EXPECTED" ]; then
  echo "FAIL: podinfo in $NAMESPACE has the label environment='$LABEL'; it must be $EXPECTED."
  exit 1
fi

MESSAGE=""
for _ in $(seq 1 20); do
  MESSAGE="$(kubectl -n gitea exec deploy/tester -- sh -c "curl -s --max-time 5 http://podinfo.$NAMESPACE:9898 | jq -r .message" 2>/dev/null)"
  [ "$MESSAGE" = "$EXPECTED" ] && break
  sleep 3
done
if [ "$MESSAGE" != "$EXPECTED" ]; then
  echo "FAIL: podinfo in $NAMESPACE answers with the message '$MESSAGE'; it must be $EXPECTED."
  exit 1
fi

echo "PASS: podinfo in $NAMESPACE runs $EXPECTED_REPLICAS replica(s), labelled and answering $EXPECTED."
exit 0
