#!/usr/bin/env bash
# PASS when a reconciliation was handled after the fix and podinfo answers staging.
set -uo pipefail
handled="$(kubectl -n flux-system get kustomization apps-staging -o jsonpath='{.status.lastHandledReconcileAt}' 2>/dev/null)"
if [ -z "$handled" ]; then
  echo "FAIL: no reconciliation was requested by hand. Run: flux reconcile kustomization apps-staging"
  exit 1
fi
message="$(kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message' 2>/dev/null)"
if [ "$message" != "staging" ]; then
  echo "FAIL: podinfo in podinfo-staging answers '$message', expected staging."
  exit 1
fi
echo "PASS: a reconciliation was requested and podinfo answers staging."
exit 0
