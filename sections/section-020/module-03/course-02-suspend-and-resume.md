# Suspend And Resume

Sometimes you need Flux to stop touching an object: an incident where you scale by hand, a migration in progress, a stage that you want frozen while you investigate. This part shows how to stop the reconciliation of one Flux `Kustomization`, what stops and what does not, and how to start again.

## What suspend does

The field `spec.suspend: true` tells kustomize-controller to skip the object. It does not fetch, build, apply or prune for it. Objects that the Flux `Kustomization` applied earlier stay in the cluster exactly as they are, and a manual change to them is not corrected. The object itself keeps the status of its last run.

Two commands set the field for you. `flux suspend kustomization` sets `spec.suspend` to `true`, and `flux resume kustomization` sets it to `false` and triggers a reconciliation at once. Using the commands, instead of editing the field, makes the intent clear in your shell history.

## Suspend a stage and change the cluster

Suspend the stage and scale its Deployment by hand:

<!-- astrona:playground:renew -->

```sh
flux suspend kustomization apps-staging
flux get kustomizations
kubectl -n podinfo-staging scale deployment podinfo --replicas=3
```

The table shows `SUSPENDED` as `True` for `apps-staging`. After the scale command, wait longer than a few seconds and look at the Deployment:

```sh
kubectl -n podinfo-staging get deployment podinfo
```

It keeps 3 replicas. A Flux `Kustomization` that is not suspended would put the replica count back to the value of Git at its next reconciliation. This is the point of suspending: you can change the live object without Flux undoing the change.

## Resume

Resume the stage:

```sh
flux resume kustomization apps-staging
kubectl -n podinfo-staging get deployment podinfo
```

The resume command reconciles the object at once. The Deployment returns to 1 replica, the value in Git, because kustomize-controller applies the folder again and the live value differs. Resuming ends the freeze and also ends your manual change.

## What suspend does not stop

Suspending a Flux `Kustomization` does not suspend its source. source-controller keeps fetching the repository, so the next artifact is already waiting when you resume. It also does not suspend other objects: a stage that depends on the suspended one keeps reading the `Ready` condition that the suspended object last reported, and a new commit does not reach the cluster through the suspended object. To freeze the fetching as well, suspend the `GitRepository` with `flux suspend source git fleet`.

A suspended object is easy to forget. The column `SUSPENDED` in `flux get kustomizations` is the place to look first when a change does not arrive.

You can now stop and restart the reconciliation of one object and predict what the cluster does in the meantime. The open question is how to run a reconciliation on request, without waiting for the clock.

## Common pitfalls

> [!WARNING]
> - **Suspending and forgetting.** A suspended stage never applies anything. Check the column `SUSPENDED` when a commit does not arrive.
> - **Expecting resume to keep manual changes.** It reconciles at once and puts the live object back to the state of Git.
> - **Suspending only the Flux `Kustomization` and expecting no fetches.** The source keeps fetching until you suspend it too.
