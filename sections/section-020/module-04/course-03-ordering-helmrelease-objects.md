# Ordering HelmRelease Objects

Two charts can depend on each other: an application chart that needs a database chart, or a chart that expects the definitions of another chart. A `HelmRelease` has its own `dependsOn`, so that helm-controller handles the order and the stage that applies the releases does not have to. This part shows the field, how a waiting release looks, and when to prefer it.

## The field

In the spec of a `HelmRelease`, `dependsOn` is a list of entries with a `name` and, when the other release lives in another namespace, a `namespace`. helm-controller checks the `Ready` condition of each named `HelmRelease` before it installs or upgrades this one. If one is not ready, it waits and tries again, and the release shows the reason `DependencyNotReady`.

Add a second release to the folder `infrastructure/podinfo-chart` in the clone. It is a copy of podinfo under another name that waits for the first one. Save this as `infrastructure/podinfo-chart/helmrelease-frontend.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: frontend
spec:
  interval: 10m
  dependsOn:
    - name: podinfo
  chart:
    spec:
      chart: podinfo
      version: 6.15.0
      sourceRef:
        kind: HelmRepository
        name: podinfo
  values:
    replicaCount: 1
```

Add the file to `kustomization.yaml` under `resources`, commit, push and reconcile with the source:

```sh
git add infrastructure/podinfo-chart
git commit -m "Add the frontend release"
git push origin main
flux reconcile kustomization chart --with-source
```

Then check the result:

```sh
flux get helmreleases -n podinfo-staging
```

Both releases are ready. `frontend` installed after `podinfo` was ready. To see the waiting state, suspend `podinfo` with `flux suspend helmrelease podinfo -n podinfo-staging` and create `frontend` again: it reports `DependencyNotReady` with the name of the release it waits for. Resume the first release with `flux resume helmrelease podinfo -n podinfo-staging`.

## What helm-controller checks

The `HelmRelease` dependency reads the `Ready` condition of the other release. It does not look at the pods of the other chart. A release is `Ready` when its Helm install or upgrade succeeded, and, when the field `install.disableWait` or `upgrade.disableWait` is not set, when Helm waited for the resources to become ready. The ordering is only as strong as that readiness.

## Which order to use

Use `dependsOn` in a `HelmRelease` when two releases belong together and live in the same folder, so that one Flux `Kustomization` applies both. Use `dependsOn` between Flux `Kustomization` objects when the dependency spans folders, teams or kinds. The two combine: stage ordering for the big picture, release ordering for details inside a stage. A health check on the stage with `wait: true` still judges all the releases in it.

You can now order two releases and tell when to use which `dependsOn`. The last case of the module is the ordering of definitions and their custom resources.

## Common pitfalls

> [!WARNING]
> - **A wrong namespace.** An entry without `namespace` means the namespace of the release that holds the entry. A release in another namespace is not found and the dependency waits for ever.
> - **A loop between releases.** helm-controller does not report it. Both releases wait.
> - **Expecting the order of the files in the folder to matter.** Flux ignores it. Only `dependsOn` orders.
