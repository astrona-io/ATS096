# Prerequisites

Before starting this lab you should be able to:

- Read a `HelmRelease` and say what `driftDetection.mode` and `driftDetection.ignore` do.
- Write a JSON Pointer to one field of a Kubernetes object.
- Use `flux reconcile helmrelease` and read the `Drifted` condition.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The Secret `fleet-auth` and the `GitRepository` `fleet` in `flux-system`, already `Ready`, following the branch `main`.
- The namespaces `podinfo-staging` and `podinfo-production`.
- The `HelmRepository` `podinfo` in `flux-system` and the `HelmRelease` `podinfo` in `podinfo-production` (2 replicas), installed and `Ready`. The environment needs outbound internet.
- A CPU request of `50m` on the `podinfo` container, set by hand by the platform team.

## Working rules

- Everything is graded on the **final state** of the cluster and the repository, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- You do not need to change anything in Git for this task. Change the Flux objects in the cluster.
