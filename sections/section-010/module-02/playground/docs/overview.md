# Overview: Build Environments With Kustomize Files (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, connects Flux to the repository, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6.** The `flux` command-line tool is on your PATH, and the Flux controllers run in the namespace `flux-system`.
- The **`GitRepository` `fleet`** in `flux-system`, already `Ready`, following the branch `main` of `gitops/fleet` with the credentials in the Secret `fleet-auth`. No Flux `Kustomization` exists yet.
- **Gitea**, an in-cluster Git server, in the namespace `gitea`, behind the Service `gitea-http` on port `3000`. It uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.
- The private repository **`gitops/fleet`**, branch `main`:

  | Path | What it holds |
  | --- | --- |
  | `apps/podinfo/base/` | `deployment.yaml` (Deployment `podinfo`, 1 replica, reads the ConfigMap `podinfo-config` with `envFrom`), `service.yaml`, and the Kustomize file `kustomization.yaml` that lists them. No namespace is set |
  | `apps/podinfo/overlays/staging/` | A Kustomize file with `namespace: podinfo-staging` and 1 replica, and a plain `configmap.yaml` with the message `staging` |
  | `apps/podinfo/overlays/production/` | A Kustomize file with `namespace: podinfo-production` and 2 replicas, and a plain `configmap.yaml` with the message `production` |
  | `apps/podinfo/components/resource-limits/` | A Kustomize `Component` that adds CPU and memory limits to the Deployment |
  | `clusters/kind/` | A short `README.md` only |

- The empty namespaces **`podinfo-staging`** and **`podinfo-production`**.
- A **`tester`** pod in the namespace `gitea`, with `curl` and `jq`.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` inside the cluster, and on your machine while a port-forward runs in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `show_flux` prints the Flux sources and every Flux `Kustomization`. `podinfo_message` sends one request to `podinfo` in the namespace you name and prints the message it answers with. `clone_fleet` clones the repository into the folder `fleet` (the port-forward must be running).

```sh
show_flux() {
  flux get sources git
  flux get kustomizations
}
podinfo_message() {
  kubectl -n gitea exec deploy/tester -- sh -c "curl -s http://podinfo.$1:9898 | jq -r .message"
}
clone_fleet() {
  git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
}
```

Use them like this: `show_flux`, `podinfo_message podinfo-staging`, `clone_fleet`.

## Practice tasks

- Run `kubectl kustomize apps/podinfo/overlays/production` in your clone and find the namespace, the replica count and the ConfigMap in the output.
- Create one Flux `Kustomization` per overlay and compare `kubectl get deployment -A -l app=podinfo`.
- Add `images` with `newTag` to the staging overlay Kustomize file and read the image in the built output.
- Replace `configmap.yaml` in the staging overlay with a `configMapGenerator`, push, and list the ConfigMaps before and after.
- Add a `secretGenerator` with a literal and check that the Secret name ends in a hash.
- Add `components: - ../../components/resource-limits` to the production overlay and compare the Deployment before and after.
