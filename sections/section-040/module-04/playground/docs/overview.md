# Overview: Helm Drift And Field Ownership (Playground)

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

- Set `driftDetection.mode: warn` on the production release, scale the Deployment by hand, and read the `Drifted` condition and the events with `release_conditions` and `flux events`.
- Change the mode to `enabled` and watch the replicas return to 2 after `flux reconcile helmrelease`.
- Add an ignore rule for `/spec/replicas` with the target kind `Deployment`, then set 4 replicas with `--field-manager=autoscaler` and reconcile.
- Write a rule with a typo in the path and confirm that it ignores nothing.
- Add a rule with a `target` that names the Deployment `podinfo`, and a second rule for a name that does not exist. Check which one has an effect.
- Edit the `HelmRelease` itself by hand in `podinfo-production` and find out whether anything puts it back.
