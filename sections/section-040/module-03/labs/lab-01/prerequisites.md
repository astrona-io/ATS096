# Prerequisites

Before starting this lab you should be able to:

- Read the inventory of a Flux `Kustomization`.
- Explain what pruning deletes and why.
- Clone the repository, commit and push.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea** with the private repository `gitops/fleet` (user `gitops`, password `gitops-password`), reachable at `http://gitea.localtest.me:3000/gitops/fleet.git` inside the cluster, and from your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The `GitRepository` `fleet` in `flux-system`, already `Ready`.
- The Flux `Kustomization` objects `team-a` and `team-b`.

## Working rules

- Everything is graded on the final state of the cluster and the repository.
- Change one thing at a time and check again.
