# Solution

## Step 1: Write the release

`targetNamespace` places the objects, `storageNamespace` places Helm's Secrets, `releaseName` stops the name from getting the namespace as a prefix, `install.createNamespace` creates `podinfo-app`, and `maxHistory` limits the revisions.

Save this as `helmrelease-podinfo.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo-staging
spec:
  interval: 10m
  releaseName: podinfo
  targetNamespace: podinfo-app
  storageNamespace: podinfo-staging
  maxHistory: 3
  install:
    createNamespace: true
  chart:
    spec:
      chart: podinfo
      version: 6.15.0
      sourceRef:
        kind: HelmRepository
        name: podinfo
        namespace: flux-system
```

```sh
kubectl apply -f helmrelease-podinfo.yaml
astrona submit
```

The first check should pass; the second can still fail while the release installs.

## Step 2: Wait and check

```sh
flux reconcile helmrelease podinfo -n podinfo-staging --with-source
flux get helmreleases -n podinfo-staging
kubectl -n podinfo-app get deployment podinfo
kubectl -n podinfo-staging get secrets -l owner=helm,name=podinfo
astrona submit
```

If the install fails with a missing namespace, check that `install.createNamespace` is `true`.
