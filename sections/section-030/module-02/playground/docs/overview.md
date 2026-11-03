# Overview: Choose And Pin Chart Sources (Playground)

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

- Create a `HelmRelease` for podinfo and find the `HelmChart` it created, with its artifact URL and revision.
- Ask for chart version `9.9.9` and find the error on the `HelmChart`, not on the release.
- Use the range `6.x`, then `~6.15.0`, and compare the revision of the `HelmChart` each time.
- Add the chart `charts/hello` to `gitops/fleet`, install it with `reconcileStrategy: Revision`, and push a template change without a version bump. Then repeat with `ChartVersion` and compare.
- Add a values file to the chart and select it with `valuesFiles`. Put the same key in `spec.values` and find out which one wins.
- Apply the `OCIRepository` with `verify` for the podinfo chart, then change the subject pattern so that it cannot match and read the condition.
