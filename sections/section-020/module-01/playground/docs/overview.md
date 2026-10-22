# Overview: Order And Gate Deployments With dependsOn And Health Checks (Playground)

This is a **playground**, not a lab. It starts a fresh cluster, installs an in-cluster Git server and Flux, connects Flux to the repository, and then waits. There is no task, no `astrona submit` and no pass or fail. Explore, break things, `astrona destroy`, start over.

## What's in the box

- A single-node `kind` Kubernetes cluster. `kubectl` is already pointed at it.
- **Flux v2.9.6.** The `flux` command-line tool is on your PATH, and the Flux controllers run in the namespace `flux-system`.
- The **`GitRepository` `fleet`** in `flux-system`, already `Ready`, following the branch `main` of `gitops/fleet`. No Flux `Kustomization` exists yet.
- **Gitea**, an in-cluster Git server, in the namespace `gitea`, behind the Service `gitea-http` on port `3000`, with the lab-only user `gitops` and the password `gitops-password`.
- The private repository **`gitops/fleet`**, branch `main`:

  | Path | What it holds |
  | --- | --- |
  | `infrastructure/redis/` | The namespace `infrastructure`, and the Deployment and Service `redis` (`redis:7.4-alpine`, port `6379`) |
  | `apps/podinfo/base/` | The Deployment and Service `podinfo`, without a namespace, using `tcp://redis.infrastructure:6379` as its cache, with the variables `${environment}` and `${message}` |
  | `clusters/kind/` | A short `README.md` only |

- The empty namespaces **`podinfo-staging`** and **`podinfo-production`**.
- A **`tester`** pod in the namespace `gitea`, with `curl` and `jq`.

The repository answers at `http://gitea.localtest.me:3000/gitops/fleet.git` inside the cluster, and on your machine while a port-forward runs in a second terminal:

```sh
kubectl -n gitea port-forward svc/gitea-http 3000:3000
```

`gitea.localtest.me` resolves to `127.0.0.1`. If your router blocks that answer, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

## Helpers

Paste these once in each new terminal. `show_pipeline` prints every Flux `Kustomization` with its ready state, revision and message. `podinfo_version` asks `podinfo` in the namespace you name for its version and message. `clone_fleet` clones the repository into the folder `fleet` (the port-forward must be running).

```sh
show_pipeline() {
  flux get kustomizations
}
podinfo_version() {
  kubectl -n gitea exec deploy/tester -- sh -c "curl -s http://podinfo.$1:9898 | jq -c '{version, message}'"
}
clone_fleet() {
  git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
}
```

Use them like this: `show_pipeline`, `podinfo_version podinfo-production`, `clone_fleet`.

## Practice tasks

- Create `apps-staging` with a dependency on a name that does not exist, and read the message of `DependencyNotReady`.
- Set `wait: false` on `infrastructure`, break the `redis` image tag in Git, and watch `apps-staging` go ahead anyway.
- Replace `wait: true` on `apps-staging` with a `healthChecks` entry for the Deployment `podinfo` in `podinfo-staging`, and confirm it behaves the same.
- Set `timeout: 20s` on a stage and find out whether a normal rollout still passes.
- Push a bad commit, then make production depend on nothing, and watch the bad commit reach production.
- Measure how long production takes to follow a fixed staging with `retryInterval: 30s` and without it.
