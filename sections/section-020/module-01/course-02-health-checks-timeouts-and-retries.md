# Health Checks, Timeouts And Retries

A Flux `Kustomization` can apply a Deployment whose pods never start, and still report success: the API server stored every object, so as far as the apply goes, nothing failed. A dependency on such an object protects nothing. This part makes `Ready` mean that the workloads run. You compare the three ways to health-check, break one on purpose, and see how `timeout` and `retryInterval` shape the result.

## Three ways to check health

A health check is the step after the apply, in which kustomize-controller waits until the applied objects are healthy. For a Deployment, healthy means that the rollout finished and the new pods are ready. A Flux `Kustomization` offers three ways to ask for it:

| Field | What kustomize-controller checks |
| --- | --- |
| `wait: true` | Every object it applied. `healthChecks` is ignored when `wait` is on |
| `healthChecks` | Only the objects in the list, each named by `apiVersion`, `kind`, `name` and `namespace` |
| `healthCheckExprs` | Custom resources, with Common Expression Language (CEL) rules that say when an object of a kind is healthy |

`wait: true` is the simple choice and the one the objects in your playground use. `healthChecks` fits when the folder holds many objects but only a few matter, or when the important object lives elsewhere, such as a Deployment that another tool creates. `healthCheckExprs` is for kinds Flux does not know how to judge. Each entry has `apiVersion` (only the group is matched), an optional `kind`, and the expressions `inProgress`, `failed` and `current`, which kustomize-controller tries in that order; the first one that is true decides. A Flux `Kustomization` that applies cert-manager certificates could add:

```yaml
  healthCheckExprs:
    - apiVersion: cert-manager.io/v1
      kind: Certificate
      failed: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'False')
      current: status.conditions.filter(e, e.type == 'Ready').all(e, e.status == 'True')
```

Your playground has no cert-manager, so this block is only an example of the shape.

## Timeout and retryInterval

Two fields decide how long a failing check takes and how often it runs again. `timeout` is the time budget for the whole reconciliation, including the health check. When the workloads are not healthy within it, the Flux `Kustomization` becomes not ready with the reason `HealthCheckFailed`. `retryInterval` is how long kustomize-controller waits before it tries again after a failure; without it, it waits a whole `interval`.

So with `timeout: 1m` and `retryInterval: 30s`, a broken Deployment is reported after about a minute, and checked again every 30 seconds after that. A long timeout hides failures for longer. A short one reports a slow but healthy rollout as a failure.

## Break a health check on purpose

The fastest way to understand a health check is to make one fail. The field `images` of a Flux `Kustomization` changes the image tag of every matching container. Give `apps-staging` a tag that does not exist, and a short timeout, so the new pods can never start.

<!-- astrona:playground:renew -->

Run `kubectl -n flux-system edit kustomization apps-staging`, set `timeout: 1m`, and add this block under `spec`:

```yaml
  images:
    - name: ghcr.io/stefanprodan/podinfo
      newTag: 0.0.0-missing
```

Then watch the result:

```sh
flux reconcile kustomization apps-staging
flux get kustomizations
kubectl -n podinfo-staging get pods
```

The reconcile command returns with an error after about a minute. `apps-staging` shows `READY` as `False`, and the message says the health check failed and names the Deployment. The new pod is in `ImagePullBackOff`, and the old pod still runs: the Deployment keeps the last working version while the new one cannot start. `flux events --for Kustomization/apps-staging` shows the reason `HealthCheckFailed`.

Now remove the `images` block with `kubectl -n flux-system edit kustomization apps-staging`, set `timeout: 2m` again, and reconcile:

```sh
flux reconcile kustomization apps-staging
```

The object is `Ready` again, and the pod that could not pull its image is gone.

## What the failure did and did not do

The failed health check did not undo anything. kustomize-controller applied the new Deployment, the new pods failed, and the Deployment's own rollout logic kept the old pods running. What the health check changed is the `Ready` condition, and that is exactly what a dependent Flux `Kustomization` reads. Any object with `apps-staging` in its `dependsOn` stops at that point.

That is also why `wait: true` matters on a dependency. Without a health check, `infrastructure` would have become `Ready` the moment the `redis` Deployment was stored, even if its image could never be pulled, and `apps-staging` would have gone ahead.

You can now make `Ready` mean "running" in three ways, and you know how `timeout` and `retryInterval` shape a failure. The open question is how to use this between two environments, so that a bad commit stops in staging before it reaches production.

## Common pitfalls

> [!WARNING]
> - **`wait: true` and `healthChecks` together.** With `wait` on, the list is ignored. Pick one.
> - **A health check on a name that is not applied.** kustomize-controller waits for an object that never appears and reports `HealthCheckFailed` at the timeout. Check `kind`, `name` and `namespace` against the built objects.
> - **A timeout shorter than a normal rollout.** A large image or a slow readiness probe then fails every time, even when nothing is wrong.
> - **Reading `HealthCheckFailed` as "Flux rolled back".** Flux applied the change; the Deployment kept its old pods. The broken spec stays until Git or the Flux object changes.
