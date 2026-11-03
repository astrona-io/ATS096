# Solution: Order A Chart Before Its Consumer

Work the task yourself first. Running `astrona submit -c sections/section-020/module-04/labs/lab-01` after a step tells you which checks pass.

The grader checks the chart stage (path, namespace and a health check on the release), the dependency from `consumer` to `chart` with both `Ready`, and the results in `podinfo-staging`.

## Step 1: Create the chart stage

Save this as `kustomization-chart.yaml`:

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

## Step 2: Create the consumer stage

Save this as `kustomization-consumer.yaml`:

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

Apply it:

```sh
kubectl apply -f kustomization-consumer.yaml
```

## Step 3: Check and submit

```sh
flux get kustomizations
flux get helmreleases -n podinfo-staging
kubectl -n podinfo-staging get configmap consumer-settings
astrona submit -c sections/section-020/module-04/labs/lab-01
```

`chart` becomes `Ready` when the release is installed, and `consumer` follows.

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `wait: false` on `chart` | The stage is `Ready` when the `HelmRelease` is stored, so `consumer` does not wait for the install |
| One stage for both folders | There is no stage between the chart and its consumer |
| `helm install` by hand | Flux does not manage the release and `chart` has nothing to judge |

## Common mistakes

- A `timeout` shorter than the install, which reports a failure for a slow image pull.
- Forgetting `targetNamespace`, so the `HelmRelease` is applied into `flux-system`.
- A typo in the dependency name, which waits for ever with `DependencyNotReady`.
