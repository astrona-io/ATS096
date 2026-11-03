# Solution

## Step 1: Take the field out of Git

Flux owns the fields that are in the YAML it applies. Remove `replicas` from the file, commit, push, and let Flux apply.

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

In a second terminal:

```sh
git clone http://gitops:gitops-password@localhost:3000/gitops/fleet.git
cd fleet
sed -i.bak '/^  replicas: 1$/d' apps/podinfo/base/deployment.yaml
rm apps/podinfo/base/deployment.yaml.bak
git commit -am "Let the autoscaler own the replicas"
git push origin main
flux reconcile kustomization podinfo-staging --with-source
astrona submit
```

The first check should pass. The second can still fail.

## Step 2: Set the replicas as the autoscaler

```sh
kubectl -n podinfo-staging patch deployment podinfo --type=merge -p '{"spec":{"replicas":4}}' --field-manager=autoscaler
flux reconcile kustomization podinfo-staging
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
astrona submit
```

The value stays 4 after the reconciliation. If it falls back to 1, the file in Git still sets `replicas`: check the base and any patch for the field.
