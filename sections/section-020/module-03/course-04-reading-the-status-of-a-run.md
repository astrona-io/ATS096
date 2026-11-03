# Reading The Status Of A Run

Each reconciliation leaves a record in the status of the object. Reading it is faster than guessing, and it is the first step of every investigation. This part shows the conditions, the revisions and the events, and the commands that print them in a form that is easy to read.

## Conditions

The field `status.conditions` of a Flux `Kustomization` is a list. The condition `Ready` says whether the last reconciliation succeeded: `True` when the objects were applied and the health check passed, `False` when something failed. Its `reason` names the result, for example `ReconciliationSucceeded`, `DependencyNotReady`, `BuildFailed` or `HealthCheckFailed`. The condition `Reconciling` is `True` while a reconciliation is running. The condition `Healthy` reports the health check on its own.

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get kustomization apps-staging -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

The output has one line for each condition. A healthy stage shows `Ready=True` with the reason `ReconciliationSucceeded`.

## Revisions

The status keeps two revisions. `status.lastAttemptedRevision` is the revision of the source that the last run tried. `status.lastAppliedRevision` is the revision that was applied and became healthy. They are equal on a healthy stage. When they differ, the last run failed and the cluster still holds the older revision:

```sh
kubectl -n flux-system get kustomization apps-staging -o jsonpath='{.status.lastAttemptedRevision}{"\n"}{.status.lastAppliedRevision}{"\n"}'
```

Each revision has the form `main@sha1:` followed by the commit hash. The same text appears in the column `REVISION` of `flux get kustomizations`.

## Events

Conditions show the last result. Events show the history. The command `flux events` lists the events that the controllers wrote for an object, with a reason and a message:

```sh
flux events --for Kustomization/apps-staging
```

A reconciliation that applied changes writes an event that lists them. One that changed nothing writes no event, which keeps the list short. A failure writes a warning event with the message of the error, which is where the full text of an error is.

## Where the objects came from

`flux tree kustomization apps-staging` prints the objects that the stage manages, from its inventory. `flux trace` goes the other way: for an object in the cluster it prints the Flux `Kustomization` that applied it and the source revision it came from.

```sh
flux tree kustomization apps-staging
flux trace deployment podinfo --namespace podinfo-staging
```

The trace names the Deployment, the Flux `Kustomization` `apps-staging`, the `GitRepository` `fleet` and the last applied revision. When someone asks which commit produced a live object, this is the command that answers.

You can now read the three kinds of record a run leaves: conditions, revisions and events. Together with the timers and the requests of the earlier parts, you can explain what the controller did, when, and why.

## Common pitfalls

> [!WARNING]
> - **Reading only the column `READY`.** The table message is cut short. Read the conditions and the events for the reason and the full text.
> - **Treating `lastAttemptedRevision` as applied.** Only `lastAppliedRevision` was applied and healthy.
> - **Expecting an event for every run.** A run that changed nothing writes none.
