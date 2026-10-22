# Solution: Override A Chart Per Environment And Survive A Bad Upgrade

Work the task yourself first. Running `astrona submit -c sections/section-030/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks four things: both releases install chart `podinfo` `6.15.0` from the `HelmRepository` with values from the ConfigMap `podinfo-values` and are `Ready`; staging and production answer with their own message and replica count; production has at least one upgrade retry with the strategy `rollback`; and Helm's storage in production holds a `failed` revision while the deployed release runs the tag `6.15.0`.

## Step 1: Create the values ConfigMaps

Save this as `configmap-podinfo-values.yaml`:

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
      message: staging
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-values
  namespace: podinfo-production
data:
  values.yaml: |
    replicaCount: 2
    ui:
      message: production
```

Apply it:

```sh
kubectl apply -f configmap-podinfo-values.yaml
```

## Step 2: Create both releases

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
  chart:
    spec:
      chart: podinfo
      version: 6.15.0
      sourceRef:
        kind: HelmRepository
        name: podinfo
        namespace: flux-system
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-values
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: podinfo
  namespace: podinfo-production
spec:
  interval: 10m
  releaseName: podinfo
  timeout: 1m
  chart:
    spec:
      chart: podinfo
      version: 6.15.0
      sourceRef:
        kind: HelmRepository
        name: podinfo
        namespace: flux-system
  valuesFrom:
    - kind: ConfigMap
      name: podinfo-values
  upgrade:
    remediation:
      retries: 1
      strategy: rollback
```

Apply it:

```sh
kubectl apply -f helmrelease-podinfo.yaml
```

Then check the result:

```sh
flux get helmreleases -A
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-production:9898 | jq -r .message'
```

Both releases are `Ready`; podinfo answers `staging` and `production`.

## Step 3: Push a bad upgrade to production

Run `kubectl -n podinfo-production edit configmap podinfo-values` and add the bad tag to the values file, so `values.yaml` reads:

```yaml
    replicaCount: 2
    ui:
      message: production
    image:
      tag: 0.0.0-missing
```

Then reconcile and follow it:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
flux events --for HelmRelease/podinfo -n podinfo-production
kubectl -n podinfo-production get secrets -l owner=helm -L version,status
```

The reconcile reports a failure after a few minutes. The events show the upgrade failing at the timeout, a rollback, one more try, and a second rollback; the release is not ready and `Stalled`. Helm's storage holds `failed` revisions, and the newest revision is `deployed`. podinfo kept answering `production` the whole time.

## Step 4: Fix the values

Remove the `image` block from the ConfigMap again with `kubectl -n podinfo-production edit configmap podinfo-values`, then reconcile:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
flux get helmreleases -n podinfo-production
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The values changed, so the failure counters reset and the upgrade succeeds. The release is `Ready`, and the Deployment runs `ghcr.io/stefanprodan/podinfo:6.15.0`.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Values inline in the `HelmRelease` | It works, but the values are no longer reviewable apart from the release, and the grader checks `valuesFrom` |
| No remediation, then fix the values by hand | Production sits failed until someone notices, which is what the task is about |
| Delete the `HelmRelease` and create it again | Helm's storage starts from revision 1, and the record of the failure is gone |

## Common mistakes

- The ConfigMap key `values.yml` instead of `values.yaml`, which the default `valuesKey` does not find.
- Forgetting `namespace: flux-system` in `sourceRef`.
- Checking the release before helm-controller has finished the rollback. Follow the events until the last rollback.
