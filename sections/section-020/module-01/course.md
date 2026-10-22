# Order And Gate Deployments With dependsOn And Health Checks

The `podinfo` application uses a `redis` cache. If Flux applies both at the same time, `podinfo` starts while `redis` is still pulling its image, and the first minutes of logs fill with connection errors. Worse, a commit that breaks `podinfo` reaches staging and production in the same minute, because each Flux `Kustomization` applies its folder as soon as the commit arrives.

Flux has two tools for this. `dependsOn` makes a Flux `Kustomization` wait until other Flux objects are `Ready`. Health checks decide what `Ready` means: not "the objects were stored", but "the workloads run". A Flux `Kustomization` is the Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`, which tells kustomize-controller which folder to build and apply; it is not the Kustomize file `kustomization.yaml`.

Keep one sentence in mind: **`dependsOn` waits for `Ready`, and health checks decide what `Ready` means.** One without the other gives you order without proof, or proof without order.

The module has three parts. **Ordering With dependsOn** deploys `redis` and then `podinfo`, and shows what a waiting Flux `Kustomization` reports. **Health Checks, Timeouts And Retries** compares `wait`, `healthChecks` and `healthCheckExprs` and breaks a health check on purpose. **A Staged Pipeline From Staging To Production** connects staging and production and stops a bad commit in staging. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Add `dependsOn` to a Flux `Kustomization` and read the reason `DependencyNotReady` and its message.
- Explain why a dependency without a health check gives order but no guarantee.
- Choose between `wait: true`, `healthChecks` and `healthCheckExprs`, and write each one.
- Explain what `timeout` and `retryInterval` control, and predict how long a failing health check takes to report.
- Build a three-stage pipeline (infrastructure, staging, production) with `dependsOn` and health checks.
- Show that a bad commit stops in staging while production keeps the last good version.

## Before you start

You need Kubernetes basics (namespaces, Deployments, Services, readiness probes) and basic Git (`clone`, `commit`, `push`, `revert`). You should know that a `GitRepository` makes source-controller fetch a repository, and that a Flux `Kustomization` makes kustomize-controller apply one folder of it, with `targetNamespace` and `postBuild.substitute` to adapt it per environment.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| `GitRepository` `fleet` | Already `Ready`. It follows the branch `main` of `gitops/fleet` |
| `infrastructure/redis` | The namespace `infrastructure`, and a Deployment and Service `redis` (`redis:7.4-alpine`, port `6379`) |
| `apps/podinfo/base` | The `podinfo` Deployment and Service, without a namespace. podinfo uses `tcp://redis.infrastructure:6379` as its cache, and the variables `${environment}` and `${message}` |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

No Flux `Kustomization` exists yet; you create them from files you save. On a real cluster they live in Git too, under `clusters/<cluster name>/`. The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git`, inside the cluster and on your machine while a port-forward to Gitea runs. The lab-only user is `gitops` with the password `gitops-password`.

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
