#!/usr/bin/env bash
# PASS when podinfo-production is Ready, takes its variables from the ConfigMap
# podinfo-prod-vars (not optional), and podinfo answers with the message from it.
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

field() { kubectl -n flux-system get kustomization podinfo-production -o jsonpath="$1" 2>/dev/null; }

SOURCES="$(field '{range .spec.postBuild.substituteFrom[*]}{.kind}/{.name}/{.optional}{"\n"}{end}')"
if ! printf '%s\n' "$SOURCES" | grep -qE '^ConfigMap/podinfo-prod-vars/(false)?$'; then
  echo "FAIL: podinfo-production must take its variables from the ConfigMap podinfo-prod-vars, without optional: true. Found: $SOURCES"
  exit 1
fi
if kubectl -n flux-system get configmap podinfo-production-vars >/dev/null 2>&1; then
  echo "FAIL: a second ConfigMap podinfo-production-vars exists. Use podinfo-prod-vars and do not create another one."
  exit 1
fi
[ "$(field '{.spec.suspend}')" != "true" ] || { echo "FAIL: podinfo-production is suspended."; exit 1; }

READY=""
for _ in $(seq 1 40); do
  READY="$(field '{.status.conditions[?(@.type=="Ready")].status}')"
  [ "$READY" = "True" ] && break
  sleep 3
done
[ "$READY" = "True" ] || { echo "FAIL: podinfo-production is not Ready: $(field '{.status.conditions[?(@.type=="Ready")].message}')"; exit 1; }

EXPECTED="production from ConfigMap"
MESSAGE=""
for _ in $(seq 1 20); do
  MESSAGE="$(kubectl -n gitea exec deploy/tester -- sh -c 'curl -s --max-time 5 http://podinfo.podinfo-production:9898 | jq -r .message' 2>/dev/null)"
  [ "$MESSAGE" = "$EXPECTED" ] && break
  sleep 3
done
[ "$MESSAGE" = "$EXPECTED" ] || { echo "FAIL: podinfo in podinfo-production answers '$MESSAGE'; it must answer '$EXPECTED'."; exit 1; }

echo "PASS: production is Ready and answers with the values from podinfo-prod-vars."
exit 0
