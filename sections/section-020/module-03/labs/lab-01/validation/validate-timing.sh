#!/usr/bin/env bash
# PASS when apps-staging has interval 5m, retryInterval 1m and timeout 3m.
set -uo pipefail
get() { kubectl -n flux-system get kustomization apps-staging -o jsonpath="{.spec.$1}" 2>/dev/null; }
for pair in interval:5m retryInterval:1m timeout:3m; do
  field="${pair%%:*}"; want="${pair##*:}"
  have="$(get "$field")"
  if [ "$have" != "$want" ]; then
    echo "FAIL: spec.$field is '$have', expected $want."
    exit 1
  fi
done
echo "PASS: interval 5m, retryInterval 1m and timeout 3m."
exit 0
