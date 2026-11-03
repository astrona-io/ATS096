# Prerequisites

Before starting this lab you should be able to:

- Read a `HelmRepository` and a `HelmRelease`.
- Say which namespace each of `metadata.namespace`, `targetNamespace` and `storageNamespace` decides.
- Use `flux get helmreleases` and `kubectl get secrets -l owner=helm`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea** and the `GitRepository` `fleet`, which this lab does not use.
- The `HelmRepository` `podinfo` in `flux-system`, pointing at `https://stefanprodan.github.io/podinfo`. The environment needs outbound internet to fetch the chart.
- The namespaces `podinfo-staging` and `podinfo-production`. The namespace `podinfo-app` does not exist.
- No `HelmRelease`.

## Working rules

- Everything is graded on the final state of the cluster, so check `flux get` at the end.
- Change one thing at a time and check again.
- You do not need to change the repository for this task.
