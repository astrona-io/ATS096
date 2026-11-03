# A HelmRelease Inside A Gated Kustomization

The usual way to install a chart with Flux is to keep the `HelmRepository` and the `HelmRelease` as YAML files in Git, and let a Flux `Kustomization` apply them. That Flux `Kustomization` can then act as a gate: it is `Ready` when the release works. This part builds the chart stage, adds a consumer stage behind it, and watches them become ready in order.

## Put the chart in Git

A `HelmRepository` is the Flux object that makes source-controller fetch the index of a chart repository. A `HelmRelease` names a chart from it and its values, and helm-controller installs it. Clone the repository and add both objects to a folder:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
mkdir -p infrastructure/podinfo-chart
```

Save this as `infrastructure/podinfo-chart/helmrepository.yaml`:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: podinfo
spec:
  interval: 10m
  url: https://stefanprodan.github.io/podinfo
```

Save this as `infrastructure/podinfo-chart/helmrelease.yaml`:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
spec:
  interval: 10m
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

Save this as `infrastructure/podinfo-chart/kustomization.yaml`, then commit and push:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - helmrepository.yaml
  - helmrelease.yaml
```

```sh
git add infrastructure/podinfo-chart
git commit -m "Add the podinfo chart"
git push origin main
```

## Gate on the release

The chart stage applies the folder into `podinfo-staging`. With `wait: true`, the stage is `Ready` only when every applied object is healthy, and a `HelmRelease` is healthy when its `Ready` condition is `True`, that is when the install succeeded. Save this as `kustomization-chart.yaml`, outside the clone:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: chart
  namespace: flux-system
spec:
  interval: 10m
  retryInterval: 1m
  path: ./infrastructure/podinfo-chart
  prune: true
  wait: true
  timeout: 5m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
```

Apply it:

```sh
kubectl apply -f kustomization-chart.yaml
```

Then check the result:

```sh
flux get kustomizations
flux get helmreleases -n podinfo-staging
```

The stage `chart` shows `READY` as `Unknown` or `False` while helm-controller installs the release, and becomes `True` when the release is ready. The `HelmRelease` shows the release deployed. The stage is the gate, and the release is the object it judges.

## Add the consumer

A consumer is any stage that needs the chart to exist. Add a folder with a ConfigMap, and a stage with `dependsOn`. Save this as `apps/consumer/configmap.yaml` and `apps/consumer/kustomization.yaml` in the clone, then push:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: consumer-settings
data:
  backend: http://podinfo:9898
```

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - configmap.yaml
```

```sh
git add apps/consumer
git commit -m "Add the consumer"
git push origin main
```

Save this as `kustomization-consumer.yaml` and apply it:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: consumer
  namespace: flux-system
spec:
  interval: 10m
  retryInterval: 1m
  path: ./apps/consumer
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-staging
  dependsOn:
    - name: chart
  sourceRef:
    kind: GitRepository
    name: fleet
```

```sh
kubectl apply -f kustomization-consumer.yaml
flux get kustomizations
```

`consumer` becomes `Ready` after `chart`. If you create `consumer` while `chart` still installs, it reports `DependencyNotReady` first. The order comes from the health of the release, as the module said.

You can now gate a stage on a `HelmRelease` and order a consumer behind it. Charts often depend on other charts, which `HelmRelease` objects can order directly, as the next part shows.

## Common pitfalls

> [!WARNING]
> - **`wait: false` on the chart stage.** The stage is then `Ready` when the `HelmRelease` is stored, not when the chart is installed, and the consumer goes ahead too early.
> - **A `timeout` shorter than the install.** The chart needs time to pull its image. A short timeout reports a failure for a slow but healthy install.
> - **Applying the objects with `kubectl` and not through the stage.** The consumer then waits for a stage that does not exist.

## Your mission: Order A Chart Before Its Consumer

You can now put a chart in a gated stage and a consumer behind it. The mission gives you the folders in Git and asks for the two stages.

Pause the playground first:

```sh
astrona stop ats-096-playground-020-04
```

Start the lab and submit when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-020/module-04/labs/lab-01
astrona submit -c sections/section-020/module-04/labs/lab-01
```

When the lab is done, remove it and start the playground again:

```sh
astrona destroy ats-096-lab-020-04
astrona start ats-096-playground-020-04
```
