# Read Kustomize Controller Errors

When a build or an apply fails in the cluster, kustomize-controller records the failure in three places: the status of the Flux `Kustomization`, the events about it, and its own log. Each place has a different level of detail. This part teaches you to read them in order, to match a failure reason to the step that failed, and to tell which revision of Git Flux actually applied.

## Break a Flux Kustomization on purpose

The quickest way to learn the messages is to cause them. Save this as `kustomization-podinfo-broken.yaml`. Its path does not exist in the repository:

<!-- astrona:playground:renew -->

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-broken
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/missing
  prune: true
  targetNamespace: podinfo-production
  sourceRef:
    kind: GitRepository
    name: fleet
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo-broken.yaml
```

Then check the result:

```sh
flux get kustomizations
```

The object `podinfo-broken` shows `READY` as `False`, and the `MESSAGE` column names the missing path. The status line is the first level: it tells you that something failed and gives the most recent message.

## Level one: the status

`flux get kustomizations` shows a short message. The full status is in the object. Run:

```sh
kubectl -n flux-system get kustomization podinfo-broken -o yaml
```

Read the field `status.conditions`. The condition `Ready` has `status: "False"`, a `reason` and a `message`. The reason is a short word that names the step that failed:

| Reason | The step that failed |
| --- | --- |
| `ArtifactFailed` | Fetching the artifact of the source, or finding the `path` in it |
| `BuildFailed` | The Kustomize build or the substitution of variables |
| `ReconciliationFailed` | Applying the objects to the cluster, for example a rejected object or a missing namespace |
| `HealthCheckFailed` | The objects were applied, but `wait` or `healthChecks` did not see them become ready |
| `DependencyNotReady` | An object in `dependsOn` is not `Ready` yet |
| `PruneFailed` | Deleting objects that left Git |

The reason tells you where to look first. A `BuildFailed` is reproduced on your machine with `kubectl kustomize` or `flux build`. A `ReconciliationFailed` is not: the build worked, and the cluster refused the result.

## Level two: events

Events are shorter notes that kustomize-controller writes each time something happens. They show a sequence, not only the last state. Read them with:

```sh
flux events --for Kustomization/podinfo-broken
```

The list has one entry for each reconciliation attempt, with the same message as the status. When a Flux `Kustomization` flips between `Ready` and `Not Ready`, the events show when. The same list is in `kubectl describe kustomization podinfo-broken -n flux-system` under `Events`.

## Level three: the controller log

The log of kustomize-controller holds the most detail, and it also covers every object, not only one. Filter it to the object:

```sh
flux logs --kind=Kustomization --name=podinfo-broken --namespace=flux-system
```

Each line is a JSON log entry with a time, a level, the object name, and the message. The same entries are in `kubectl -n flux-system logs deploy/kustomize-controller`, without the filter. Use the log when the status message is cut short or when an error has no event, for example when the controller itself restarts.

## Applied versus attempted revision

The status of a Flux `Kustomization` records two revisions. `status.lastAttemptedRevision` is the revision of the source that kustomize-controller tried last. `status.lastAppliedRevision` is the last revision that was applied successfully.

When a build fails on a new commit, the two differ: the attempted revision is the new commit, and the applied revision is the last good one. Print both:

```sh
kubectl -n flux-system get kustomization podinfo-broken -o jsonpath='{.status.lastAttemptedRevision}{"\n"}{.status.lastAppliedRevision}{"\n"}'
```

For `podinfo-broken` the applied revision is empty, because nothing was ever applied. For a Flux `Kustomization` that worked and then broke, the applied line shows the last good commit. That is the most useful question in an incident: what is running now, and which commit broke it. The old objects keep running while the new commit fails, because Flux applies nothing from a failed build.

## Reconcile to look again

After you fix the cause, you do not have to wait for the interval. Ask Flux to fetch the source and reconcile in one step:

```sh
flux reconcile kustomization podinfo-broken --with-source
```

Without `--with-source`, the command reconciles the Flux `Kustomization` with the artifact it already has. With it, source-controller fetches the newest commit first. After a push, use `--with-source`, or the Flux `Kustomization` still builds the old commit.

Clean up the broken object when you are done:

```sh
kubectl -n flux-system delete kustomization podinfo-broken
```

You can now read a failure at three levels and connect a reason to a step. The open question is the case where the Flux `Kustomization` is `Ready` and the cluster still is not what you expect. That needs a way to start from a live object and walk back.

## Common pitfalls

> [!WARNING]
> - **Reading only the `READY` column.** It says `False` but not why. Read the reason and the message.
> - **Fixing the wrong step.** `ReconciliationFailed` is not a build error. Do not edit the Kustomize file before you know which step failed.
> - **Reconciling without `--with-source` after a push.** The Flux `Kustomization` then builds the commit it already had.
> - **Assuming a failed build removes the application.** The objects of the last good revision keep running.

## Your mission: Repair A Build That Uses Replacements

You can now read the status, the events and the log of a failing Flux `Kustomization`, and you know how a replacement is written. The graded lab gives you a Flux `Kustomization` that is not `Ready` and an overlay with a replacement, and asks you to find both faults, repair them, and prove that the Deployment shows the message from the ConfigMap.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-096-playground-010-03
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-010/module-03/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-096-lab-010-03
astrona start ats-096-playground-010-03
```
