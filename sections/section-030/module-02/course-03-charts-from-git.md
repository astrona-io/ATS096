# Charts From Git

Teams that write their own charts keep them in the same repository as the rest of their configuration. Flux installs such a chart straight from a folder of a `GitRepository`, with no chart repository in between. This part adds a small chart to the repository, installs it with a `HelmRelease`, and selects a values file that belongs to the chart.

## A chart in the repository

A chart is a folder with a `Chart.yaml` file, a `values.yaml` file of defaults and a `templates` folder. Clone the repository and create a chart named `hello` that writes one ConfigMap:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
mkdir -p charts/hello/templates
```

Save this as `charts/hello/Chart.yaml`:

```yaml
apiVersion: v2
name: hello
description: A chart with one ConfigMap
version: 0.1.0
appVersion: "1.0.0"
```

Save this as `charts/hello/values.yaml`:

```yaml
message: default
```

Save this as `charts/hello/values-staging.yaml`:

```yaml
message: staging
```

Save this as `charts/hello/templates/configmap.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  message: {{ .Values.message | quote }}
```

Commit and push the chart:

```sh
git add charts/hello
git commit -m "Add the hello chart"
git push origin main
```

## Install it with a HelmRelease

For a chart in Git, `sourceRef` points at the `GitRepository`, and `chart` is the path of the chart folder. `valuesFiles` lists files of the chart, relative to the chart folder, that are merged over `values.yaml` in order. Save this as `helmrelease-hello.yaml`, outside the clone:

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

Apply it:

```sh
kubectl apply -f helmrelease-hello.yaml
```

Then check the result:

```sh
flux get sources chart -n podinfo-staging
flux get helmreleases -n podinfo-staging
kubectl -n podinfo-staging get configmap hello-config -o jsonpath='{.data.message}{"\n"}'
```

The `HelmChart` revision is the commit of the repository, because the strategy is `Revision`. The ConfigMap holds `staging`: the second values file replaced the default. The order of `valuesFiles` matters, and a value in `spec.values` of the release wins over both files.

## A change without a version bump

Edit `charts/hello/templates/configmap.yaml` in the clone and add a second line under `data`, for example `owner: platform`. Commit and push, and ask Flux to fetch:

```sh
git commit -am "Add the owner"
git push origin main
flux reconcile helmrelease hello -n podinfo-staging --with-source
```

The `version` in `Chart.yaml` did not change, but the strategy `Revision` makes the `HelmChart` produce a new artifact for every commit. The release upgrades, and the ConfigMap has the new key. With the default `ChartVersion`, nothing would have happened.

You can now install a chart from Git, merge values files, and pick the strategy that lets edits arrive. The mission uses all three.

## Common pitfalls

> [!WARNING]
> - **A `sourceRef` to a `GitRepository` in another namespace without `namespace`.** The default is the namespace of the release.
> - **`valuesFiles` paths relative to the repository.** They are relative to the chart folder.
> - **The default strategy for a chart under development.** Edits without a version bump never arrive.
> - **A chart path without `./`.** Write `./charts/hello`.

## Your mission: Install A Chart From Git With A Values File

You can now install a chart from a path in Git and select its values files. The mission gives you the chart in the repository and asks for the release.

Pause the playground first:

```sh
astrona stop ats-096-playground-030-02
```

Start the lab and submit when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-030/module-02/labs/lab-01
astrona submit -c sections/section-030/module-02/labs/lab-01
```

When the lab is done, remove it and start the playground again:

```sh
astrona destroy ats-096-lab-030-02
astrona start ats-096-playground-030-02
```
