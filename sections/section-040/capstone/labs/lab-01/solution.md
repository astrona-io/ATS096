# Solution: Keep Two Environments Equal To Git

Work the task yourself first. Running `astrona submit -c sections/section-040/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `podinfo-staging` prunes, is `Ready`, and the leftover ConfigMap is gone; the `ssa` annotation is gone from Git and staging answers `staging v2`; and production has drift detection `enabled` and puts a manual scale back to 2.

## Step 1: Find out why staging keeps the old message

```sh
kubectl -n flux-system get kustomization podinfo-staging -o jsonpath='{.spec.postBuild.substitute}{"\n"}'
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.metadata.annotations}{"\n"}'
```

The Flux object asks for `staging v2`, and it is `Ready`. The live Deployment carries the annotation `kustomize.toolkit.fluxcd.io/ssa: IfNotPresent`: kustomize-controller created it once and has skipped it ever since. The annotation comes from Git, so it must be removed in Git.

## Step 2: Remove the annotation in Git

Start the port-forward in a second terminal (`kubectl -n gitea port-forward svc/gitea-http 3000:3000`), clone, and open `fleet/apps/podinfo/base/deployment.yaml`. If `gitea.localtest.me` does not resolve, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
```

Delete the three lines under `metadata` that start with `annotations:`, the comment, and `kustomize.toolkit.fluxcd.io/ssa: IfNotPresent`. Then commit and push:

```sh
git -C fleet commit -am "Let Flux manage the podinfo Deployment again"
git -C fleet push
```

## Step 3: Turn pruning on and clean up the leftover

Run `kubectl -n flux-system edit kustomization podinfo-staging` and set:

```yaml
  prune: true
```

Then reconcile and check:

```sh
flux reconcile kustomization podinfo-staging --with-source
kubectl -n podinfo-staging get configmap podinfo-legacy-settings
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
```

podinfo now answers `staging v2`: without the annotation, kustomize-controller applies the Deployment again. The ConfigMap is still there, because it dropped off the inventory while pruning was off, so pruning does not know about it. It is not managed by anything now, so delete it once by hand:

```sh
kubectl -n podinfo-staging delete configmap podinfo-legacy-settings
```

## Step 4: Make production correct drift

Run `kubectl -n podinfo-production edit helmrelease podinfo` and change the mode:

```yaml
  driftDetection:
    mode: enabled
```

Then reconcile and check:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo
```

The Deployment is back at 2 replicas.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Remove the annotation from the live Deployment only | The next apply puts it back from Git, and later changes are skipped again |
| Delete the staging Deployment so `IfNotPresent` creates it fresh | The message is right today, and the next change in Git is skipped again |
| Scale production back by hand | It works once; with `warn`, the next manual scale stays again |
| Keep `prune: false` and delete the ConfigMap | The next file removed from Git leaves another object behind |

## Common mistakes

- Expecting `prune: true` to delete the leftover ConfigMap. It only deletes objects on the inventory.
- Committing without the port-forward running, so `git push` cannot reach Gitea.
- Reconciling without `--with-source`, so kustomize-controller still builds the old commit.
