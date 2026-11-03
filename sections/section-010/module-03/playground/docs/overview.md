# Overview: Replacements And Debugging Builds (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, connects Flux to the repository, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6.** The `flux` command-line tool is on your PATH, and the Flux controllers run in the namespace `flux-system`.
- The **`GitRepository` `fleet`** in `flux-system`, already `Ready`, following the branch `main` of `gitops/fleet` with the credentials in the Secret `fleet-auth`. No Flux `Kustomization` exists yet.
- **Gitea**, an in-cluster Git server, in the namespace `gitea`, behind the Service `gitea-http` on port `3000`. It uses plain HTTP and the lab-only user `gitops` with the password `gitops-password`.
- The private repository **`gitops/fleet`**, branch `main`:

  | Path | What it holds |
  | --- | --- |
  | `apps/podinfo/base/` | `deployment.yaml` (Deployment `podinfo`, 1 replica, port `9898`, environment variable `PODINFO_UI_MESSAGE` with the value `placeholder`), `service.yaml`, and the Kustomize file `kustomization.yaml` that lists them. No namespace is set |
  | `apps/podinfo/overlay/` | A Kustomize file that lists the base and `settings.yaml`, and a `replacements` block that copies `data.message` of the ConfigMap `podinfo-settings` into `PODINFO_UI_MESSAGE`. `settings.yaml` holds the message `from-replacement` |
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

- Run `kubectl kustomize apps/podinfo/overlay` and find the value of `PODINFO_UI_MESSAGE` in the output.
- Change the `options` of the replacement with a `delimiter` and an `index` to replace one part of a string value.
- Break the source `fieldPath` on purpose, push, and read the error with `flux get kustomizations`, `flux events --for Kustomization/<name>` and `kubectl describe`.
- Set a `path` that does not exist on a Flux `Kustomization` and read the message.
- Run `flux diff kustomization <name> --path ./apps/podinfo/overlay` before and after a change, and read the exit code with `echo $?`.
- Run `flux trace podinfo --kind deployment --api-version apps/v1 --namespace podinfo-staging` and follow the chain from the Deployment to the Git source.
