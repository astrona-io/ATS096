# Judge Custom Resources With CEL Health Checks

A Flux `Kustomization` reports `Ready` when its health check passes. For a Deployment, Flux knows what healthy means. For an object of a kind that Flux has never seen, such as a `Widget` defined by a team of your own, Flux has no rule. This module teaches the rule you can give it: expressions written in the Common Expression Language (CEL), which tell kustomize-controller when an object of a kind is in progress, failed or healthy.

Keep one sentence in mind: **when Flux cannot read the status of a kind, you write the rule in `healthCheckExprs`.** Every command in this module tests that sentence.

The module has four parts. **Why Custom Resources Need A Health Rule** shows that an object without a status is called healthy at once. **Writing healthCheckExprs** adds the three expressions to a Flux `Kustomization`. **Testing An Expression** changes the status of the object by hand and watches `Ready` change. **Reusable Expressions** shows the patterns for conditions, counters and generations. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Explain how kustomize-controller decides that an object is healthy when no expression exists.
- Write `healthChecks` and `healthCheckExprs` for a custom resource.
- Explain the order in which `inProgress`, `failed` and `current` are tried.
- Change the status of an object with `kubectl patch --subresource=status` to test a rule.
- Write expressions with `filter`, `all`, `exists` and comparisons on status fields.

## Before you start

You need Kubernetes basics (namespaces, custom resource definitions, `kubectl patch`) and basic Git (`clone`, `commit`, `push`). You should know that a Flux `Kustomization` (the Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`, not the Kustomize file `kustomization.yaml`) applies a folder of a Git source.

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
