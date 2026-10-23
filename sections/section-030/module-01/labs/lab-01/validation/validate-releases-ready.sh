#!/usr/bin/env bash
# PASS when both HelmReleases install chart podinfo 6.15.0 from the
# HelmRepository podinfo, take their values from the ConfigMap podinfo-values
# (not optional), and are Ready.
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

for namespace in podinfo-staging podinfo-production; do
  field() { kubectl -n "$namespace" get helmrelease podinfo -o jsonpath="$1" 2>/dev/null; }
  if ! kubectl -n "$namespace" get helmrelease podinfo >/dev/null 2>&1; then
    echo "FAIL: the HelmRelease podinfo does not exist in $namespace."
    exit 1
  fi
  [ "$(field '{.spec.chart.spec.chart}')" = "podinfo" ] || { echo "FAIL: the HelmRelease in $namespace must install the chart podinfo through spec.chart."; exit 1; }
  [ "$(field '{.spec.chart.spec.version}')" = "6.15.0" ] || { echo "FAIL: the HelmRelease in $namespace must pin the chart version 6.15.0."; exit 1; }
  [ "$(field '{.spec.chart.spec.sourceRef.kind}/{.spec.chart.spec.sourceRef.name}')" = "HelmRepository/podinfo" ] || { echo "FAIL: the HelmRelease in $namespace must use the HelmRepository podinfo."; exit 1; }
  [ "$(field '{.spec.releaseName}')" = "podinfo" ] || { echo "FAIL: the HelmRelease in $namespace must use the release name podinfo."; exit 1; }
  SOURCES="$(field '{range .spec.valuesFrom[*]}{.kind}/{.name}/{.optional}{"\n"}{end}')"
  if ! printf '%s\n' "$SOURCES" | grep -qE '^ConfigMap/podinfo-values/(false)?$'; then
    echo "FAIL: the HelmRelease in $namespace must take its values from the ConfigMap podinfo-values, not optional. Found: $SOURCES"
    exit 1
  fi
  [ "$(field '{.spec.suspend}')" != "true" ] || { echo "FAIL: the HelmRelease in $namespace is suspended."; exit 1; }
  READY=""
  for _ in $(seq 1 60); do
    READY="$(field '{.status.conditions[?(@.type=="Ready")].status}')"
    [ "$READY" = "True" ] && break
    sleep 3
  done
  [ "$READY" = "True" ] || { echo "FAIL: the HelmRelease in $namespace is not Ready: $(field '{.status.conditions[?(@.type=="Ready")].message}')"; exit 1; }
done

echo "PASS: both HelmReleases install podinfo 6.15.0 with values from podinfo-values and are Ready."
exit 0
