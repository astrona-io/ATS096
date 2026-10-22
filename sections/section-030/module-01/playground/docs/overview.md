# Overview: Deploy Helm Charts With HelmRelease (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs Flux and waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6.** The `flux` command-line tool is on your PATH, and the Flux controllers run in the namespace `flux-system`: source-controller, kustomize-controller, helm-controller and notification-controller.
- The empty namespaces **`podinfo-staging`** and **`podinfo-production`**. No `HelmRepository`, `OCIRepository` or `HelmRelease` exists yet.
- A **`tester`** pod in the namespace `gitea`, with `curl` and `jq`.
- **Gitea** and the `GitRepository` `fleet`, which this module does not use.

The chart comes from the internet: `https://stefanprodan.github.io/podinfo` (chart repository) and `oci://ghcr.io/stefanprodan/charts/podinfo` (OCI registry). The `helm` command is not installed; read releases with `flux` and `kubectl`.

## Helpers

Paste these once in each new terminal. `show_releases` prints every Helm source, chart and release. `release_history` prints Helm's storage Secrets of the release `podinfo` in the namespace you name, with revision and status. `podinfo_message` asks `podinfo` in that namespace for its message.

```sh
show_releases() {
  flux get sources helm -A
  flux get sources oci -A
  flux get sources chart -A
  flux get helmreleases -A
}
release_history() {
  kubectl -n "$1" get secrets -l owner=helm,name=podinfo -L version,status
}
podinfo_message() {
  kubectl -n gitea exec deploy/tester -- sh -c "curl -s http://podinfo.$1:9898 | jq -r .message"
}
```

Use them like this: `show_releases`, `release_history podinfo-production`, `podinfo_message podinfo-staging`.

## Practice tasks

- Ask for chart version `9.9.9` and find the error on the `HelmChart`, not on the release.
- Add the same value inline and in a `valuesFrom` ConfigMap, and check which one podinfo answers with.
- Change the ConfigMap of staging and compare the release before and after `flux reconcile helmrelease`.
- Point `valuesFrom` at a key that does not exist, then set `optional: true`, and explain the difference.
- Use the strategy `uninstall` for a bad upgrade and compare Helm's storage with the `rollback` case.
- Leave out `releaseName` and find the name of the Service the chart created.
