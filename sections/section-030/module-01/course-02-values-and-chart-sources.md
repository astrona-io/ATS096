# Values, valuesFrom And OCI Chart Sources

Inline values are fine for a demo, but they put every environment's configuration inside the object that installs the chart. Teams usually want the values somewhere else: in a ConfigMap that a values file creates, or in a Secret when a value is sensitive. Charts also move: more and more of them are published to container registries instead of chart repositories. This part moves the staging values into a ConfigMap and installs production from an OCI registry.

## Where values come from

A `HelmRelease` can take values from two fields, and helm-controller merges them into one set before each install or upgrade:

| Field | What it holds |
| --- | --- |
| `spec.valuesFrom` | A list of ConfigMaps and Secrets in the namespace of the `HelmRelease`. Each entry has `kind`, `name`, `valuesKey` (default `values.yaml`), an optional `targetPath`, and `optional` (default `false`) |
| `spec.values` | Values written in the `HelmRelease` itself |

helm-controller merges the `valuesFrom` entries in the order of the list, so a later entry overrides an earlier one, and then merges `spec.values` on top. With `targetPath`, an entry sets one value instead of a whole file: the content of `valuesKey` becomes the value at that path, such as `ui.message`. That is how a single key of a Secret becomes one chart value.

## Move the staging values into a ConfigMap

The chart's values file goes into the ConfigMap under the key `values.yaml`, the default `valuesKey`.

<!-- astrona:playground:renew -->

Save this as `configmap-podinfo-values-staging.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-values
  namespace: podinfo-staging
data:
  values.yaml: |
    replicaCount: 1
    ui:
      message: staging from ConfigMap
```

Apply it:

```sh
kubectl apply -f configmap-podinfo-values-staging.yaml
```

Now point the release at it and remove the inline values. Run `kubectl -n podinfo-staging edit helmrelease podinfo`, delete the `values:` block, and add this block under `spec`:

```yaml
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-values
```

Then check the result:

```sh
flux reconcile helmrelease podinfo -n podinfo-staging
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
kubectl -n podinfo-staging get secrets -l owner=helm -L status,version
```

podinfo answers `staging from ConfigMap`. The merged values changed, so helm-controller ran an upgrade: Helm's storage now has revision `2` with the status `deployed`, and revision `1` is `superseded`. helm-controller does not watch the ConfigMap by default; a change to it is picked up at the next reconciliation of the `HelmRelease`, or at once with `flux reconcile helmrelease`.

## Install production from an OCI registry

The same chart is published to the GitHub container registry as an Open Container Initiative (OCI) artifact, at `oci://ghcr.io/stefanprodan/charts/podinfo`. An OCI registry stores charts the way it stores container images, by name and tag. Flux reads it with an `OCIRepository`, and a `HelmRelease` uses it through `spec.chartRef` instead of `spec.chart`. A `HelmRelease` has exactly one of the two.

The `OCIRepository` lives next to the release and selects the chart layer of the artifact. Save this as `ocirepository-podinfo-chart.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo-chart
  namespace: podinfo-production
spec:
  interval: 1h
  url: oci://ghcr.io/stefanprodan/charts/podinfo
  ref:
    tag: 6.15.0
  layerSelector:
    mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
    operation: copy
```

Apply it:

```sh
kubectl apply -f ocirepository-podinfo-chart.yaml
```

Now the release. Production takes one value, the message, from a Secret with `targetPath`, and the rest inline. Save this as `helmrelease-podinfo-production.yaml`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: podinfo-message
  namespace: podinfo-production
stringData:
  message: production
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo-production
spec:
  interval: 10m
  releaseName: podinfo
  chartRef:
    kind: OCIRepository
    name: podinfo-chart
  valuesFrom:
    - kind: Secret
      name: podinfo-message
      valuesKey: message
      targetPath: ui.message
  values:
    replicaCount: 2
```

Apply it:

```sh
kubectl apply -f helmrelease-podinfo-production.yaml
```

Then check the result:

```sh
flux get sources oci -n podinfo-production
flux get helmreleases -A
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-production:9898 | jq -r .message'
```

The `OCIRepository` is `Ready` with the tag `6.15.0` in its revision, the release in `podinfo-production` is `Ready` with 2 replicas, and podinfo answers `production`. No `HelmChart` was created this time: with `chartRef`, helm-controller uses the artifact of the `OCIRepository` directly.

You can now keep values outside the `HelmRelease`, combine whole values files with single values, and install from both kinds of chart source. The open question is what helm-controller does when the values are wrong and an upgrade cannot work.

## Common pitfalls

> [!WARNING]
> - **A values ConfigMap in another namespace.** `valuesFrom` reads only from the namespace of the `HelmRelease`.
> - **The wrong `valuesKey`.** A ConfigMap with the key `values.yml` is not found under the default `values.yaml`, and the reconciliation fails.
> - **Expecting a ConfigMap change to roll out at once.** helm-controller reads it at the next reconciliation. Use `flux reconcile helmrelease`.
> - **`chart` and `chartRef` together.** A `HelmRelease` must have exactly one of them.
