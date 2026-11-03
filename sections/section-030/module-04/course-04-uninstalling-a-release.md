# Uninstalling A Release

Deleting a `HelmRelease` is not deleting a Kubernetes object. It is a request to run an uninstall, and helm-controller finishes it before the object disappears. This part shows how that works, what an uninstall leaves behind, and how to control it.

## Delete means uninstall

A `HelmRelease` has a finalizer, a marker that tells Kubernetes not to remove the object until a controller says so. When you delete the object, helm-controller runs the Helm uninstall for the release, then removes the finalizer, and only then is the `HelmRelease` gone.

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-staging delete helmrelease podinfo
kubectl get deployment -n podinfo-app
kubectl -n podinfo-staging get secrets -l owner=helm
```

The Deployment is gone, and so are the Helm Secrets. The namespace `podinfo-app` stays, because `createNamespace` creates a namespace but the uninstall does not delete it.

When the Flux `Kustomization` that applies the `HelmRelease` has `prune: true`, removing the file from Git deletes the object and therefore uninstalls the release. This is the normal way to remove a chart in GitOps.

## Controlling the uninstall

| Field | Effect |
| --- | --- |
| `spec.uninstall.timeout` | Time allowed for the uninstall, default from `spec.timeout` |
| `spec.uninstall.disableWait` | Do not wait for the objects to be gone |
| `spec.uninstall.keepHistory` | Keep the release Secrets after the objects are removed |
| `spec.uninstall.deletionPropagation` | How dependents are deleted: `background`, `foreground` or `orphan` |

`keepHistory: true` leaves the record in Helm's storage with the status `uninstalled`. It is useful when you want to read the last values and manifest after the fact.

## Leave the objects but stop managing them

Sometimes you want Flux to forget a release while its objects keep running. Deleting the `HelmRelease` would uninstall it. Suspending does not delete; it only stops the work, and the objects stay. To hand a release over to another tool, suspend it first and then remove the finalizer by hand, which skips the uninstall:

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"suspend":true}}'
```

Removing a finalizer by hand is a last resort and leaves the Helm Secrets and objects without an owner. Do it only when you accept that.

## A release that will not go away

If the uninstall cannot finish, for example because an object is stuck, the `HelmRelease` stays in the state `Terminating`. Read the status with `flux get helmreleases` and `flux events`, fix the object that blocks, and the uninstall completes. Setting `uninstall.disableWait: true` before the delete avoids waiting on objects that are slow to leave.

You can now remove a release deliberately, keep its record when it helps, and recover when it will not go away. Together with the earlier parts you can place, size, upgrade and remove a release.

## Common pitfalls

> [!WARNING]
> - **Deleting a `HelmRelease` to stop managing it.** It uninstalls the chart.
> - **Expecting the namespace to be removed.** Uninstall deletes the chart's objects, not the namespace.
> - **Removing the finalizer by hand.** The Helm Secrets and objects stay behind.
> - **Pruning a whole folder by accident.** Every release in it is uninstalled.
