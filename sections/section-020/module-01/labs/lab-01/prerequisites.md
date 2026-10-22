# Prerequisites

Before starting this lab you should be able to:

- Read a Flux `Kustomization` with `dependsOn`, `wait`, `healthChecks` and `timeout`.
- Use `flux get kustomizations`, `flux tree kustomization` and `flux events`.
- Send a request from one pod to another with `kubectl exec` and `curl`.

## What the environment gives you

The lab environment builds itself before the task begins:

- A single-node `kind` Kubernetes cluster, with `kubectl` already pointed at it.
- **Flux v2.9.6**: the `flux` command-line tool on your PATH, and the Flux controllers in the namespace `flux-system`.
- **Gitea**, an in-cluster Git server, with the private repository `gitops/fleet` (lab-only user `gitops`, password `gitops-password`). The address `http://gitea.localtest.me:3000/gitops/fleet.git` works inside the cluster, and on your machine while `kubectl -n gitea port-forward svc/gitea-http 3000:3000` runs.
- The Secret `fleet-auth` and the `GitRepository` `fleet` in `flux-system`, already `Ready`, following the branch `main`.
- The namespaces `podinfo-staging` and `podinfo-production`.
- In the repository, the folders `infrastructure/redis` (namespace `infrastructure`, Deployment and Service `redis`) and `apps/podinfo/base` (podinfo, using redis as its cache, with the variables `${environment}` and `${message}`). No Flux `Kustomization` exists yet.

## Working rules

- Everything is graded on the **final state** of the cluster and the repository, so check `flux get` at the end and leave the fix in place.
- Change one thing at a time and check again. A second change made before you check the first makes it impossible to know which one worked.
- You do not need to change anything in Git for this task. Change the Flux objects in the cluster.
