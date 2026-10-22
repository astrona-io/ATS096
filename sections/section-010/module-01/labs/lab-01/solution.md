# Solution: Deploy One Base To Two Environments

Work the task yourself first. Running `astrona submit -c sections/section-010/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: both Flux `Kustomization` objects build `./apps/podinfo/base` into their own namespace with pruning on and are `Ready`; staging runs 1 replica with the label and message `staging`; production runs 2 replicas with the label and message `production`. It also checks that Flux applied the Deployments, by looking for them in the inventory of each Flux `Kustomization`.

## Step 1: Look at the base

Check the source and read the variables the base uses. Start the port-forward to Gitea in a second terminal first (`kubectl -n gitea port-forward svc/gitea-http 3000:3000`):

```sh
flux get sources git
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
grep -n '\${' fleet/apps/podinfo/base/deployment.yaml
```

The source `fleet` is `Ready`. The Deployment uses two variables, `${environment:=dev}` in its labels and `${message:=deployed by Flux}` in `PODINFO_UI_MESSAGE`, and it has `replicas: 1`. So staging needs only values, and production needs values plus a patch for the replica count.

## Step 2: Create the staging copy

Save this as `kustomization-podinfo-staging.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-staging
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
  postBuild:
    substitute:
      environment: staging
      message: staging
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo-staging.yaml
```

## Step 3: Create the production copy

Production adds a strategic merge patch for the replica count. Save this as `kustomization-podinfo-production.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-production
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-production
  sourceRef:
    kind: GitRepository
    name: fleet
  patches:
    - patch: |
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: podinfo
        spec:
          replicas: 2
      target:
        kind: Deployment
        name: podinfo
  postBuild:
    substitute:
      environment: production
      message: production
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo-production.yaml
```

Taking the production values from a ConfigMap in `flux-system` with `substituteFrom` is just as correct; the grader checks the result, not where the values come from.

## Step 4: Prove both environments

```sh
flux get kustomizations
kubectl get deployment podinfo -n podinfo-staging -L environment
kubectl get deployment podinfo -n podinfo-production -L environment
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-production:9898 | jq -r .message'
```

Both Flux objects are `Ready`. Staging shows 1 ready replica with `environment` set to `staging` and answers `staging`. Production shows 2 ready replicas with `production` and answers `production`. If a message still shows the old value, the new pod is still rolling out; run the request again after a few seconds.

## Step 5: Submit

```sh
astrona submit -c sections/section-010/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Change `replicas` to 2 in the base | Staging gets 2 replicas too, and the base is no longer shared as it is |
| Copy the base into two folders | It works today, and the next fix lands in one copy only |
| `kubectl apply` the manifests into both namespaces | Nothing deploys them from Git; the grader finds no Deployment in the Flux inventory |
| Leave out `postBuild` | Both environments answer `deployed by Flux` and carry `environment: dev` |

## Common mistakes

- Forgetting the `|` after `patch:`, so the patch is read as fields of the Flux object and the apply is refused.
- Putting a values ConfigMap in the application namespace instead of `flux-system`.
- Checking the message right after the apply, before the new pod is ready.

## Practice on your own

- Move the production values into a ConfigMap and use `substituteFrom`.
- Add the label `team: platform` to production with a JSON6902 patch.
- Run `flux diff kustomization podinfo-production --path ./apps/podinfo/base` from your clone and explain why it reports no differences.
