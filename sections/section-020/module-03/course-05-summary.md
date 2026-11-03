# Summary

kustomize-controller reconciles a Flux `Kustomization` in a cycle with three timers. `interval` is the wait after a success and the clock that corrects drift. `retryInterval` is the wait after a failure and falls back to `interval`. `timeout` is the budget of one run, including the health check, and it also falls back to `interval`. A new commit follows another clock, the `interval` of the `GitRepository`.

`spec.suspend` stops the cycle for one object. Nothing is built, applied or pruned, the live objects stay as they are, manual changes are not corrected, and the source keeps fetching. `flux resume` starts the cycle again with an immediate run, which puts the live objects back to the state of Git.

A run can be requested. `flux reconcile` writes the annotation `reconcile.fluxcd.io/requestedAt`, the controller copies it to `status.lastHandledReconcileAt` when it handled the request, and `--with-source` fetches the source first. A request does not change the schedule and does not skip `dependsOn` or health checks.

The record of a run is in the status. The conditions `Ready`, `Reconciling` and `Healthy` give the result and its reason, `lastAttemptedRevision` and `lastAppliedRevision` show which revision was tried and which one is live, `flux events` gives the history, and `flux tree` and `flux trace` connect objects to their source revision.

- Set `retryInterval` on every stage that waits for something.
- A timeout must be longer than a normal rollout.
- Suspend is a freeze, and resume ends the freeze with a reconciliation.
- Use `--with-source` after a push.

<!-- astrona:playground:destroy -->
