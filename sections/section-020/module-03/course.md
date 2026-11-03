# Control The Reconciliation Lifecycle

A Flux `Kustomization` is not a one-time command. kustomize-controller reconciles it again and again: it fetches the state of the source, builds, applies and checks health, and then waits for the next turn. This module explains the timing of that cycle, how to pause it and restart it, how to ask for an immediate run, and how to read the status that each run leaves behind.

Keep one sentence in mind: **a reconciliation is a run of the controller with a clock, a budget and a record.** The clock is `interval` and `retryInterval`, the budget is `timeout`, and the record is the status of the object.

The module has four parts. **Interval, Timeout And Retry** names the three timers and measures them. **Suspend And Resume** stops the cycle and shows what stops with it. **Requesting A Reconciliation** asks for an immediate run with `flux reconcile` and with an annotation. **Reading The Status Of A Run** reads conditions, revisions and events. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Explain what `interval`, `retryInterval` and `timeout` control, and set each one.
- Suspend and resume a Flux `Kustomization`, and say what stays unchanged while it is suspended.
- Request a reconciliation with `flux reconcile`, with `--with-source`, and with the annotation `reconcile.fluxcd.io/requestedAt`.
- Read the conditions `Ready` and `Reconciling`, the revisions and the events of a Flux `Kustomization`.
- Find which source revision an object applied with `flux trace` and `flux tree`.

## Before you start

You need Kubernetes basics (namespaces, Deployments) and basic Git. You should know that a Flux `Kustomization` (the Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`, not the Kustomize file `kustomization.yaml`) applies a folder of a Git source.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| `GitRepository` `fleet` | Already `Ready`, following the branch `main` of `gitops/fleet` |
| `gitops/fleet` | The folders `infrastructure/redis` and `apps/podinfo/base` |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs in a second terminal. The user is `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
