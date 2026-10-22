#!/usr/bin/env bash
# PASS when every stage is health-checked against its own workload: wait: true,
# or a healthChecks entry for the Deployment the stage applies.
set -uo pipefail

check_gate() {
  local name="$1" deployment="$2" namespace="$3" wait checks
  wait="$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.spec.wait}' 2>/dev/null)"
  [ "$wait" = "true" ] && return 0
  checks="$(kubectl -n flux-system get kustomization "$name" \
    -o jsonpath='{range .spec.healthChecks[*]}{.kind}/{.namespace}/{.name}{"\n"}{end}' 2>/dev/null)"
  if printf '%s\n' "$checks" | grep -qx "Deployment/$namespace/$deployment"; then
    return 0
  fi
  echo "FAIL: $name is not health-checked against its workload. Use wait: true, or a healthChecks entry for the Deployment $deployment in $namespace. Found: $(printf '%s ' $checks)"
  return 1
}

check_gate infrastructure redis infrastructure || exit 1
check_gate apps-staging podinfo podinfo-staging || exit 1
check_gate apps-production podinfo podinfo-production || exit 1

echo "PASS: every stage is health-checked against its own Deployment."
exit 0
