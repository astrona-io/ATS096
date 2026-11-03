# Names And Namespaces

A release has three places it can live. The `HelmRelease` object is in one namespace, the objects the chart creates can be in a second, and Helm's own record of the release can be in a third. This part sets each one on purpose, and shows the effect of the default name rule.

## The three namespaces

| Field | Decides | Default |
| --- | --- | --- |
| `metadata.namespace` | Where the `HelmRelease` object lives | The namespace you apply it in |
| `spec.targetNamespace` | Where Helm installs the chart's objects | The namespace of the `HelmRelease` |
| `spec.storageNamespace` | Where Helm stores its release Secrets | The namespace of the `HelmRelease` |

Splitting them is useful when a platform team owns the `HelmRelease` objects in one namespace and applications run in their own namespaces. Then the release objects stay in a namespace that application teams cannot read, and so does the storage with its copy of every value.

## The release name

Helm identifies a release by name inside its storage namespace. With a `targetNamespace` set and no `releaseName`, the name is the target namespace and the name of the `HelmRelease` joined with a dash. With neither set, it is the name of the `HelmRelease`. Set `releaseName` when the name matters, for example when a chart builds object names from it.

## A release with its own namespace

Save this as `helmrepository-podinfo.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: flux-system
spec:
  interval: 10m
  url: https://stefanprodan.github.io/podinfo
```

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

Apply both and look at where everything is:

```sh
kubectl apply -f helmrepository-podinfo.yaml -f helmrelease-podinfo.yaml
flux reconcile helmrelease podinfo -n podinfo-staging --with-source
flux get helmreleases -n podinfo-staging
kubectl get deployment -n podinfo-app
kubectl -n podinfo-staging get secrets -l owner=helm,name=podinfo
kubectl -n podinfo-app get secrets -l owner=helm
```

The Deployment is in `podinfo-app`. The Helm Secret is in `podinfo-staging`. The last command finds no Helm Secret. `createNamespace: true` made `podinfo-app`, which did not exist; without it, the install fails with a message that the namespace is not found.

## The name is part of the identity

Helm finds a release by its name in its storage namespace. If `releaseName` changes on a live release, Helm looks for the new name, finds nothing, and tries to install a new release. The objects of the old release already exist, so the install fails because they belong to another release. The same happens when `storageNamespace` changes. Decide both once, before the first install.

You can now separate the places a release lives and keep its name stable. The next part controls how much history Helm keeps and how long it waits.

## Common pitfalls

> [!WARNING]
> - **Changing `releaseName` or `storageNamespace` on a live release.** Helm looks for the old release under the new identity, finds none, and the install collides with the existing objects.
> - **A missing target namespace.** Set `install.createNamespace` or create the namespace in Git.
> - **Forgetting the name rule.** With `targetNamespace` and no `releaseName`, the name has a prefix.
> - **Deleting the namespace of the storage.** The record of the release goes with it.
