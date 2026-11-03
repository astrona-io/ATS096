# Requesting A Reconciliation

You pushed a fix and do not want to wait for two intervals. Flux lets you ask for a reconciliation now. This part shows the command, the annotation behind it, and the option that makes the source fetch first. It also shows how to tell that your request was handled.

## What flux reconcile does

The command `flux reconcile kustomization apps-staging` writes the annotation `reconcile.fluxcd.io/requestedAt` on the object, with the current time as value. kustomize-controller watches the object, sees that the value changed and reconciles at once. The command then waits for the result and prints it. You can set the same annotation yourself with `kubectl annotate`, which is how a script or another tool asks for a run.

When the controller has handled a request, it copies the value into `status.lastHandledReconcileAt`. Comparing the two fields tells you whether your request was handled.

<!-- astrona:playground:renew -->

```sh
flux reconcile kustomization apps-staging
kubectl -n flux-system get kustomization apps-staging -o jsonpath='{.metadata.annotations.reconcile\.fluxcd\.io/requestedAt}{"\n"}{.status.lastHandledReconcileAt}{"\n"}'
```

Both lines print the same time, which means the controller handled the request.

## The source is fetched separately

Reconciling the Flux `Kustomization` does not fetch the repository. It applies the artifact that source-controller fetched last. After a push, the new commit is only available after the `GitRepository` fetched it. The option `--with-source` asks for both: it reconciles the source first, then the Flux `Kustomization`.

Change the base in Git and apply it quickly. Clone the repository and change the replicas of the Deployment, or any other value, push the commit, and then run:

```sh
flux reconcile kustomization apps-staging --with-source
```

The command prints the revision of the fetched commit and then the result of the apply. Without `--with-source`, the same command applies the old artifact and the change does not arrive until the source fetches it.

## Request with an annotation

A script can ask for a reconciliation without the `flux` tool:

```sh
kubectl -n flux-system annotate --overwrite kustomization apps-staging reconcile.fluxcd.io/requestedAt="$(date +%s)"
```

The controller treats any new value as a request, so the value is only a token that must change each time. The time in seconds is a convenient token. Read `status.lastHandledReconcileAt` afterwards to confirm that it was handled.

## What the request does not do

A requested reconciliation does not change the schedule. The next one still comes at the `interval`. It also does not skip the checks: `dependsOn` and the health check run as always, so a stage whose dependency is not ready still reports `DependencyNotReady` after your request. A request on a suspended object does nothing until you resume it.

You can now run a reconciliation on request, fetch the source first, and prove that the request was handled. The open question is how to read the record that the run leaves, which the next part shows.

## Common pitfalls

> [!WARNING]
> - **Reconciling the Flux `Kustomization` after a push and expecting the new commit.** Use `--with-source`, or wait for the source.
> - **Reusing the same annotation value.** The controller sees no change and does nothing.
> - **Requesting a reconciliation on a suspended object.** Nothing happens until you resume it.

## Your mission: Resume And Tune A Suspended Stage

You can now resume a stage, set its timers and request a reconciliation. The mission starts from a stage that someone suspended with a long interval and a very short timeout, and asks you to bring it back.

Pause the playground first:

```sh
astrona stop ats-096-playground-020-03
```

Start the lab and submit when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-020/module-03/labs/lab-01
astrona submit -c sections/section-020/module-03/labs/lab-01
```

When the lab is done, remove it and start the playground again:

```sh
astrona destroy ats-096-lab-020-03
astrona start ats-096-playground-020-03
```
