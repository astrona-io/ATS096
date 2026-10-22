# Prerequisites

Before starting this capstone you should be able to:

- Read a `HelmRelease` with `chart.spec` or `chartRef`, and an `OCIRepository`.
- Find why a `HelmRelease` is not `Ready` from its conditions, including `Stalled`.
- Read the keys of a Secret without printing its values.

## What the environment gives you

The capstone environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The Secret `fleet-auth` and the `GitRepository` `fleet` in `flux-system`, already `Ready`, following the branch `main`.
- The namespaces `podinfo-staging` and `podinfo-production`.
- The `OCIRepository` `podinfo-chart` in `podinfo-staging`, the `HelmRepository` `podinfo` in `flux-system`, the Secret `podinfo-values` in `podinfo-production`, and two `HelmRelease` objects named `podinfo`, prepared as the task describes. The environment needs outbound internet.

## Working rules

- Everything is graded on the **final state** of the cluster and the repository, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- You do not need to change anything in Git for this task. Change the Flux objects in the cluster.
