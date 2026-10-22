#!/usr/bin/env bash
# PASS when Helm's storage in podinfo-production holds at least one failed
# revision of the release podinfo, the newest revision is deployed, and the
# Deployment runs the image tag 6.15.0.
set -uo pipefail

FAILED="$(kubectl -n podinfo-production get secrets -l owner=helm,name=podinfo,status=failed -o name 2>/dev/null | wc -l | tr -d ' ')"
if [ "$FAILED" -lt 1 ]; then
  echo "FAIL: Helm's storage in podinfo-production holds no failed revision. Push the bad upgrade and let helm-controller roll it back."
  exit 1
fi

DEPLOYED="$(kubectl -n podinfo-production get secrets -l owner=helm,name=podinfo,status=deployed -o name 2>/dev/null | wc -l | tr -d ' ')"
if [ "$DEPLOYED" != "1" ]; then
  echo "FAIL: Helm's storage in podinfo-production has $DEPLOYED deployed revisions; exactly one must be deployed."
  exit 1
fi

IMAGE="$(kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)"
case "$IMAGE" in
  *:6.15.0) ;;
  *) echo "FAIL: production runs the image '$IMAGE'; the deployed release must run the tag 6.15.0."; exit 1 ;;
esac

echo "PASS: Helm's storage records $FAILED failed revision(s), and production runs a deployed release on 6.15.0."
exit 0
