#!/usr/bin/env bash
# PASS when drift detection is enabled and every ignore rule covers only the
# container resources of the Deployment.
set -uo pipefail

field() { kubectl -n podinfo-production get helmrelease podinfo -o jsonpath="$1" 2>/dev/null; }

MODE="$(field '{.spec.driftDetection.mode}')"
[ "$MODE" = "enabled" ] || { echo "FAIL: driftDetection.mode is '$MODE'; it must be enabled so drift is corrected."; exit 1; }

RULES="$(field '{range .spec.driftDetection.ignore[*]}{.target.kind}|{.paths}{"\n"}{end}')"
[ -n "$RULES" ] || { echo "FAIL: there is no ignore rule, so the tuned CPU request would be reverted."; exit 1; }

while IFS= read -r rule; do
  [ -z "$rule" ] && continue
  kind="${rule%%|*}"
  paths="${rule#*|}"
  if [ "$kind" != "Deployment" ]; then
    echo "FAIL: every ignore rule must target kind Deployment. Found a rule for '${kind:-every object}'."
    exit 1
  fi
  for path in $(printf '%s' "$paths" | tr -d '[]"' | tr ',' ' '); do
    case "$path" in
      /spec/template/spec/containers/0/resources|/spec/template/spec/containers/0/resources/*) ;;
      *) echo "FAIL: the ignore path '$path' covers more than the container resources."; exit 1 ;;
    esac
  done
done <<< "$RULES"

echo "PASS: drift detection is enabled and ignores only the container resources of the Deployment."
exit 0
