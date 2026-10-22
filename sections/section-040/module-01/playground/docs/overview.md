# Overview: Keep The Cluster Equal To Git (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, deploys podinfo twice, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6.** The `flux` command-line tool is on your PATH, and the Flux controllers run in the namespace `flux-system`.
- The **Flux `Kustomization` `podinfo-staging`**: it applies `./apps/podinfo/base` from the `GitRepository` `fleet` into `podinfo-staging`, with `prune: true`, `wait: true` and the message `staging`.
- The **`HelmRelease` `podinfo`** in `podinfo-production`: chart podinfo `6.15.0` from the `HelmRepository` `podinfo` in `flux-system`, with 2 replicas and the message `production`. It has no drift detection.
- **Gitea**, an in-cluster Git server, with the private repository **`gitops/fleet`** (lab-only user `gitops`, password `gitops-password`). `apps/podinfo/base` holds a Deployment and a Service for podinfo.
- A **`tester`** pod in the namespace `gitea`, with `curl` and `jq`.

The playground needs outbound internet for the chart. The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` inside the cluster, and on your machine while a port-forward runs in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `show_inventory` prints the inventory of `podinfo-staging`. `show_managers` prints the field managers of the podinfo Deployment in the namespace you name. `release_conditions` prints the conditions of the production release, including `Drifted`.

```sh
show_inventory() {
  kubectl -n flux-system get kustomization podinfo-staging \
    -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
}
show_managers() {
  kubectl -n "$1" get deployment podinfo --show-managed-fields \
    -o jsonpath='{range .metadata.managedFields[*]}{.manager}{"  "}{.operation}{"\n"}{end}'
}
release_conditions() {
  kubectl -n podinfo-production get helmrelease podinfo \
    -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" "}{.reason}{"\n"}{end}'
}
```

Use them like this: `show_inventory`, `show_managers podinfo-staging`, `release_conditions`.

## Practice tasks

- Add a label to the staging Deployment with plain `kubectl label`, reconcile, and check whether it stays. Then do it again with `--field-manager=flux-client-side-apply`.
- Put the annotation `kustomize.toolkit.fluxcd.io/ssa: IfNotPresent` on the Deployment in Git, change the message, and find out why staging does not change.
- Set `prune: false`, remove a file from Git, set `prune: true` again, and explain why the object stays.
- Delete `podinfo-staging` with `deletionPolicy: Orphan` and check what is left in `podinfo-staging`.
- Use `driftDetection.mode: warn` and read the drifted fields in `flux events --for HelmRelease/podinfo -n podinfo-production`.
- Write an ignore rule with a typo in the path and confirm that it ignores nothing.
