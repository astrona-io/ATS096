# Solution

## Step 1: Write the release

The chart is in Git, so `sourceRef` points at the `GitRepository`, and `chart` is a path. The release lives in `podinfo-staging` and the repository in `flux-system`, so `namespace` is needed. The strategy `Revision` makes every commit a new chart revision, and `valuesFiles` selects the files in order.

Save this as `helmrelease-hello.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: hello
  namespace: podinfo-staging
spec:
  interval: 10m
  chart:
    spec:
      chart: ./charts/hello
      reconcileStrategy: Revision
      sourceRef:
        kind: GitRepository
        name: fleet
        namespace: flux-system
      valuesFiles:
        - values.yaml
        - values-staging.yaml
```

```sh
kubectl apply -f helmrelease-hello.yaml
astrona submit
```

The first check should pass; the second can still fail while the release installs.

## Step 2: Wait for the install

```sh
flux reconcile helmrelease hello -n podinfo-staging --with-source
flux get helmreleases -n podinfo-staging
kubectl -n podinfo-staging get configmap hello-config -o jsonpath='{.data.message}{"\n"}'
astrona submit
```

The message is `staging`. If it is `default`, the second values file was not applied: check the spelling in `valuesFiles`.
