# Prerequisites

Before starting this lab you should be able to:

- Read a `HelmRelease` and say what `valuesFrom`, `valuesKey` and `targetPath` do.
- Say where a post-renderer acts and how a patch selects its target.
- Install a chart from a `GitRepository` path.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`).
- The Secret `fleet-auth` and the `GitRepository` `fleet` in `flux-system`, already `Ready`, following the branch `main`.
- The chart `charts/hello` in the repository.
- The ConfigMap `hello-message` in `podinfo-staging`.
- No `HelmRelease`.

## Working rules

- Everything is graded on the final state of the cluster, so check `flux get` at the end.
- Change one thing at a time and check again.
- You do not need to change the repository for this task.
