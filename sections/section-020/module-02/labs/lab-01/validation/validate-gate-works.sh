#!/usr/bin/env bash
# PASS when widgets is Ready, the Widget reports status.phase Running, and the
# current expression reads status.phase.
set -uo pipefail

name=widgets
current="$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.spec.healthCheckExprs[?(@.kind=="Widget")].current}' 2>/dev/null)"
if ! printf '%s' "$current" | command grep -q 'status.phase'; then
  echo "FAIL: the current expression must read status.phase. It is: '$current'"
  exit 1
fi
phase="$(kubectl -n podinfo-staging get widget gauge -o jsonpath='{.status.phase}' 2>/dev/null)"
if [ "$phase" != "Running" ]; then
  echo "FAIL: the Widget gauge in podinfo-staging has status.phase '$phase', expected Running."
  exit 1
fi
ready="$(kubectl -n flux-system get kustomization "$name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
if [ "$ready" != "True" ]; then
  echo "FAIL: widgets is not Ready. Run: flux get kustomizations"
  exit 1
fi
echo "PASS: widgets is Ready because the Widget reports Running."
exit 0
