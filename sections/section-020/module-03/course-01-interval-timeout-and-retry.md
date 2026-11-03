# Interval, Timeout And Retry

Every Flux `Kustomization` has a clock. Without it, a change in Git would never reach the cluster, and a failed apply would never be tried again. This part names the three timers, shows what each one does in a real run, and explains the choices behind their values.

## The three timers

`interval` is how often kustomize-controller reconciles the object when everything works. It is required. At each interval the controller applies the folder again, which is also how it corrects drift. `retryInterval` is the wait after a failed reconciliation. When it is not set, the controller uses `interval`, so a failure can wait as long as a success. `timeout` is the time budget of one reconciliation: the build, the apply and the health check all count against it. The default is the value of `interval`.

| Field | Used when | If unset |
| --- | --- | --- |
| `interval` | After a successful reconciliation | Required |
| `retryInterval` | After a failed reconciliation | The value of `interval` |
| `timeout` | During one reconciliation | The value of `interval` |

The intervals are about the state of the object. A new commit in Git arrives by a different clock, the `interval` of the `GitRepository`: source-controller fetches the repository on that clock, and kustomize-controller reacts when it sees a new revision. So a commit can wait for two clocks before it is applied.

## Create a stage with short timers

Save this as `kustomization-apps-staging.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: apps-staging
  namespace: flux-system
spec:
  interval: 5m
  retryInterval: 1m
  timeout: 3m
  path: ./apps/podinfo/base
  prune: true
  wait: true
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
  postBuild:
    substitute:
      environment: staging
      message: staging
```

Apply it and read the three values back:

```sh
kubectl apply -f kustomization-apps-staging.yaml
kubectl -n flux-system get kustomization apps-staging -o jsonpath='{.spec.interval} {.spec.retryInterval} {.spec.timeout}{"\n"}'
flux get kustomizations
```

The first command prints `5m 1m 3m`, and the stage becomes `Ready`. Between the intervals the controller does nothing visible. You can see that it keeps its schedule in the field `status.lastAttemptedRevision` and in the events, which this module reads later.

## Choose the values

A short `interval` makes drift disappear sooner, and costs more requests to the Kubernetes API server. For most stages ten minutes is common. A short `retryInterval` makes a stage recover soon after you fix its dependency or its Git source. A `timeout` must be longer than a normal rollout: a Deployment with a slow readiness probe needs a longer budget than a ConfigMap. If the timeout is too short, a healthy rollout is reported as failed.

You can now name the three timers and say which clock each one belongs to. The open question is how to stop the clock, which the next part covers.

## Common pitfalls

> [!WARNING]
> - **Leaving `retryInterval` unset on a stage with a dependency.** After a failure the stage waits a full `interval` before it tries again, even when the dependency became ready a minute later.
> - **A `timeout` shorter than the rollout.** Every reconciliation then fails with `HealthCheckFailed`, although nothing is wrong.
> - **Expecting a Git commit to apply at the `interval` of the object.** The `interval` of the `GitRepository` decides when the commit is fetched.
