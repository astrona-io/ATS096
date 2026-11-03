# Solution: Repair A Build That Uses Replacements

Work the task yourself first. Running `astrona submit -c sections/section-010/module-03/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: `podinfo-staging` builds `./apps/podinfo/overlay`, with no `postBuild` and no `patches`, and is `Ready`; the overlay in Git still has a replacement that reads `data.message` and the Deployment in the cluster has the replaced value; and podinfo answers `from-replacement` from a Deployment that Flux applied.

## Step 1: Read the status

```sh
flux get kustomizations
flux events --for Kustomization/podinfo-staging
```

`podinfo-staging` is not `Ready`. The message names the path `./apps/podinfo/overlays`. The repository has a folder `apps/podinfo/overlay` and no folder `apps/podinfo/overlays`, so the first fault is a typo in `spec.path`.

## Step 2: Fix the path in the cluster

Save this as `kustomization-podinfo-staging.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-staging
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/overlay
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-staging
  sourceRef:
    kind: GitRepository
    name: fleet
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo-staging.yaml
flux reconcile kustomization podinfo-staging
flux get kustomizations
```

The path now exists, but the Flux `Kustomization` still fails. The status message now comes from the build, and it reports an error about the replacement that reads `podinfo-settings`.

## Step 3: Reproduce the build error locally

Start the port-forward to Gitea in a second terminal first (`kubectl -n gitea port-forward svc/gitea-http 3000:3000`). Then clone the repository and build the overlay:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
kubectl kustomize apps/podinfo/overlay
```

The build stops with the same error as the Flux `Kustomization`. The file `apps/podinfo/overlay/settings.yaml` holds the key `message`, and the replacement in `kustomization.yaml` reads `data.msg`.

## Step 4: Fix the replacement and push

In `apps/podinfo/overlay/kustomization.yaml`, change `fieldPath: data.msg` to `fieldPath: data.message`. Then build again, and commit:

```sh
kubectl kustomize apps/podinfo/overlay
git add apps/podinfo/overlay/kustomization.yaml
git commit -m "Read the message key in the replacement"
git push origin main
flux reconcile source git fleet
flux reconcile kustomization podinfo-staging
```

The local build prints the Deployment with `PODINFO_UI_MESSAGE` set to `from-replacement`.

## Step 5: Prove it

```sh
flux get kustomizations
kubectl -n podinfo-staging get deployment podinfo
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-staging:9898 | jq -r .message'
```

`podinfo-staging` is `Ready`, the Deployment has 1 ready replica and the request answers `from-replacement`. If the answer is still `placeholder` for a moment, the new pod is still starting.

## Step 6: Submit

```sh
astrona submit -c sections/section-010/module-03/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| Set the message with `postBuild` or a patch | The grader finds `postBuild` or `patches` on the Flux `Kustomization` |
| Delete the replacement from the overlay | The grader reads the file in Git and finds no replacement |
| `kubectl set env` on the Deployment | Flux does not apply it, and the next reconciliation changes it back |
| Suspend the Flux `Kustomization` | It stops failing but also stops deploying, and the grader fails it |

## Common mistakes

- Fixing the path and stopping, because the object still is not `Ready`. Read the new message after each fix.
- Editing the file in the clone and forgetting to push before the reconcile.
- Changing `fieldPath` of the target instead of the source.

## Practice on your own

- Run `flux build kustomization podinfo-staging --path ./apps/podinfo/overlay` from your clone and compare it with `kubectl kustomize`.
- Break the target `fieldPaths` entry on purpose and read the error.
- Run `flux trace podinfo --kind deployment --api-version apps/v1 --namespace podinfo-staging` and read which Flux `Kustomization` and source it comes from.
