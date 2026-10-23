#!/usr/bin/env bash
# PASS when apps-staging depends on infrastructure, apps-production depends on
# apps-staging, and no stage is suspended.
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

depends_on() {
  kubectl -n flux-system get kustomization "$1" \
    -o jsonpath='{range .spec.dependsOn[*]}{.name}{"\n"}{end}' 2>/dev/null
}

for name in infrastructure apps-staging apps-production; do
  if ! kubectl -n flux-system get kustomization "$name" >/dev/null 2>&1; then
    echo "FAIL: the Flux Kustomization $name does not exist in flux-system."
    exit 1
  fi
  if [ "$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.spec.suspend}')" = "true" ]; then
    echo "FAIL: $name is suspended."
    exit 1
  fi
done

if ! depends_on apps-staging | grep -qx infrastructure; then
  echo "FAIL: apps-staging must depend on infrastructure. It depends on: $(depends_on apps-staging | tr '\n' ' ')"
  exit 1
fi
if ! depends_on apps-production | grep -qx apps-staging; then
  echo "FAIL: apps-production must depend on apps-staging. It depends on: $(depends_on apps-production | tr '\n' ' ')"
  exit 1
fi

echo "PASS: apps-staging waits for infrastructure, and apps-production waits for apps-staging."
exit 0
