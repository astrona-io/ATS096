# The HelmChart Between Source And Release

A `HelmRelease` does not fetch a chart itself. Between the release and the chart repository sits a third object, the `HelmChart`, and most chart problems show up on it first. This part creates a release, finds that object, and reads what it holds, so that you know which controller to ask when a chart cannot be found.

## Two controllers, one handoff

source-controller owns the sources: it reads the index of a `HelmRepository`, downloads the chart that matches, packages it and stores the result as an artifact, a `tar.gz` file served inside the cluster. helm-controller owns the releases: it installs the artifact with Helm. The `HelmChart` is the object that describes one chart to source-controller.

A `HelmRelease` that uses `spec.chart.spec` makes helm-controller create the `HelmChart` for it. The name of the object is the namespace and the name of the release joined with a dash, for example `podinfo-staging-podinfo`, and it lives in the namespace of the release.

## Create a release and find the chart

Save this as `helmrepository-podinfo.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
  namespace: podinfo-staging
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
  chart:
    spec:
      chart: podinfo
      version: 6.15.0
      sourceRef:
        kind: HelmRepository
        name: podinfo
```

Apply both:

```sh
kubectl apply -f helmrepository-podinfo.yaml
kubectl apply -f helmrelease-podinfo.yaml
```

Then check the sources and the release:

```sh
flux get sources helm -n podinfo-staging
flux get sources chart -n podinfo-staging
flux get helmreleases -n podinfo-staging
```

The first command shows the repository with a revision that is a digest of its index. The second shows the `HelmChart` `podinfo-staging-podinfo` with the revision `6.15.0`. The third shows the release `Ready`. Three objects, three controllers' records: the repository and the chart belong to source-controller, the release to helm-controller.

## Read the HelmChart

```sh
kubectl -n podinfo-staging get helmchart podinfo-staging-podinfo -o jsonpath='{.spec.chart} {.spec.version} {.spec.reconcileStrategy} {.status.artifact.url}{"\n"}'
```

The output shows the chart name, the version, the strategy (`ChartVersion` by default) and the address of the artifact inside the cluster. If the chart is missing in the repository, this object is `Ready=False` with a message that names the chart and the version, and the `HelmRelease` shows that its chart is not ready. The first question to ask about a release that does not install is therefore whether the `HelmChart` is `Ready`.

## Intervals

Two intervals matter. The `interval` of the `HelmRepository` decides how often source-controller reloads the index of the repository. The field `spec.chart.spec.interval` of the release decides how often the `HelmChart` checks the repository for a newer chart that matches a range. The default for the second is 1 minute. The `interval` of the release decides how often helm-controller reconciles the release itself.

You can now trace a release to its chart and tell which controller owns each object. The open question is which chart version the `HelmChart` selects when the release does not name an exact one.

## Common pitfalls

> [!WARNING]
> - **Debugging the release when the chart is the problem.** If the `HelmChart` is not `Ready`, helm-controller has nothing to install.
> - **Looking for the `HelmChart` in `flux-system`.** It lives in the namespace of the release, not of the repository.
> - **Mixing up the intervals.** The repository interval reloads the index, the chart interval selects a version, and the release interval reconciles the release.
