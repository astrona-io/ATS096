#!/usr/bin/env bash
# Reference remediation, applied only by `astrona test` (the `testing:` block).
# `astrona run` never runs this, so the capstone stays broken for the student.
# Taken from solution.md - if one changes, change the other. The Git change is
# made through the Gitea API from the tester pod, because `astrona test` has no
# port-forward.
set -eu

BIN_DIR="/usr/local/bin"
[ -w "$BIN_DIR" ] || BIN_DIR="$HOME/.local/bin"
export PATH="$BIN_DIR:$PATH"

GIT_USER="gitops"
GIT_PASSWORD="gitops-password"
API="http://gitea-http.gitea:3000/api/v1/repos/gitops/fleet/contents"
FILE="apps/podinfo/base/deployment.yaml"

SHA="$(kubectl -n gitea exec deploy/tester -- sh -c \
  "curl -fsS -u '$GIT_USER:$GIT_PASSWORD' '$API/$FILE?ref=main' | jq -r .sha")"
CONTENT="$(cat <<'YAML' | base64 | tr -d '\n'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  labels:
    app: podinfo
    environment: ${environment:=dev}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: podinfo
  template:
    metadata:
      labels:
        app: podinfo
    spec:
      containers:
        - name: podinfo
          image: ghcr.io/stefanprodan/podinfo:6.15.0
          env:
            - name: PODINFO_UI_MESSAGE
              value: "${message:=deployed by Flux}"
          ports:
            - name: http
              containerPort: 9898
          readinessProbe:
            httpGet:
              path: /readyz
              port: http
          resources:
            requests:
              cpu: 10m
              memory: 32Mi
YAML
)"
printf '{"content":"%s","sha":"%s","message":"Let Flux manage the podinfo Deployment again","branch":"main"}' "$CONTENT" "$SHA" \
  | kubectl -n gitea exec -i deploy/tester -- curl -fsS -u "$GIT_USER:$GIT_PASSWORD" \
      -X PUT -H 'Content-Type: application/json' --data-binary @- "$API/$FILE" >/dev/null

kubectl -n flux-system patch kustomization podinfo-staging --type=merge -p '{"spec":{"prune":true}}'
flux reconcile kustomization podinfo-staging --with-source --timeout=4m
kubectl -n podinfo-staging delete configmap podinfo-legacy-settings --ignore-not-found

kubectl -n podinfo-production patch helmrelease podinfo --type=merge \
  -p '{"spec":{"driftDetection":{"mode":"enabled"}}}'
flux reconcile helmrelease podinfo -n podinfo-production --timeout=5m
