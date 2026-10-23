#!/usr/bin/env bash
# PASS when production uses the HelmRepository podinfo in flux-system, takes
# its values from the Secret podinfo-values (not optional), keeps no inline
# values, and is Ready.
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

field() { kubectl -n podinfo-production get helmrelease podinfo -o jsonpath="$1" 2>/dev/null; }

[ "$(field '{.spec.chart.spec.sourceRef.kind}/{.spec.chart.spec.sourceRef.name}/{.spec.chart.spec.sourceRef.namespace}')" = "HelmRepository/podinfo/flux-system" ] \
  || { echo "FAIL: production must use the HelmRepository podinfo in flux-system."; exit 1; }
SOURCES="$(field '{range .spec.valuesFrom[*]}{.kind}/{.name}/{.optional}{"\n"}{end}')"
if ! printf '%s\n' "$SOURCES" | grep -qE '^Secret/podinfo-values/(false)?$'; then
  echo "FAIL: production must take its values from the Secret podinfo-values, not optional. Found: $SOURCES"
  exit 1
fi
if [ -n "$(field '{.spec.values}')" ]; then
  echo "FAIL: production has inline values. Keep its values in the Secret."
  exit 1
fi
KEYS="$(kubectl -n podinfo-production get secret podinfo-values -o jsonpath='{.data}' 2>/dev/null)"
case "$KEYS" in
  *'"values.yml"'*) ;;
  *) echo "FAIL: the Secret podinfo-values was changed; it must keep its key values.yml."; exit 1 ;;
esac

READY=""
for _ in $(seq 1 60); do
  READY="$(field '{.status.conditions[?(@.type=="Ready")].status}')"
  [ "$READY" = "True" ] && break
  sleep 3
done
[ "$READY" = "True" ] || { echo "FAIL: production is not Ready: $(field '{.status.conditions[?(@.type=="Ready")].message}')"; exit 1; }

echo "PASS: production installs from the HelmRepository with values from the Secret and is Ready."
exit 0
