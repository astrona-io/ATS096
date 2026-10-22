# Pruning, The Inventory And Deletion Policies

Drift correction handles objects that changed. It cannot handle an object whose file is gone from Git: there is nothing left to compare it with. That case needs memory. kustomize-controller keeps a list of everything it applied, and deletes what drops off the list. This part adds a file to Git, removes it again, and follows the object through that list.

## The inventory

The **inventory** is the list of objects a Flux `Kustomization` applied in its last successful reconciliation, stored in `.status.inventory`. Each entry has an `id` made of the namespace, name, API group and kind of the object, joined with underscores, and the core API group is empty. Read the inventory of staging:

<!-- astrona:playground:renew -->

```sh
kubectl -n flux-system get kustomization podinfo-staging \
  -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
```

There are two entries, one for the Deployment `podinfo` (group `apps`) and one for the Service `podinfo` (empty group), both in `podinfo-staging`. When `prune: true` is set, each reconciliation compares the new build with this list. Objects on the list and not in the build are deleted. Objects that kustomize-controller never applied are never on the list, so pruning never touches them.

## Add a file, then remove it

Start the port-forward to Gitea in a second terminal (`kubectl -n gitea port-forward svc/gitea-http 3000:3000`) and clone the repository. If `gitea.localtest.me` does not resolve, add `127.0.0.1 gitea.localtest.me` to `/etc/hosts`.

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
```

In your clone, save this as `fleet/apps/podinfo/base/configmap-podinfo-settings.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: podinfo-settings
data:
  cache: enabled
```

Then add it to the `resources` list in `fleet/apps/podinfo/base/kustomization.yaml`, commit, push and reconcile:

```sh
git -C fleet add apps/podinfo/base
git -C fleet commit -m "Add podinfo settings"
git -C fleet push
flux reconcile kustomization podinfo-staging --with-source
```

The ConfigMap `podinfo-settings` now exists in `podinfo-staging`, and the inventory has a third entry for it. Now remove it again: delete the file and its line in `kustomization.yaml`, then commit, push and reconcile:

```sh
git -C fleet rm apps/podinfo/base/configmap-podinfo-settings.yaml
git -C fleet commit -am "Remove podinfo settings"
git -C fleet push
flux reconcile kustomization podinfo-staging --with-source
kubectl -n podinfo-staging get configmap podinfo-settings
```

The last command reports that the ConfigMap is not found. kustomize-controller built the folder, saw that the ConfigMap was on the inventory and not in the build, and deleted it. The inventory is back to two entries.

## What turns pruning off

Pruning has three switches, from wide to narrow. `prune: false` on the Flux `Kustomization` turns it off for every object it applies. The annotation `kustomize.toolkit.fluxcd.io/prune: disabled` on one object in Git keeps that object when its file goes away, which fits objects such as a namespace or a PersistentVolumeClaim that must outlive a refactoring. And `kustomize.toolkit.fluxcd.io/reconcile: disabled` stops both applying and pruning for one object.

With `prune: false`, a removed file leaves its object behind, and that object then drops off the inventory at the next successful reconciliation, because the inventory records what was applied, not what exists. Turning pruning on later does not bring it back onto the list. An object left behind that way has to be deleted by hand once.

## Deletion policies

Pruning answers what happens when a file leaves Git. The **deletion policy** answers what happens when the Flux `Kustomization` itself is deleted. The field `spec.deletionPolicy` has four values:

| Value | When the Flux `Kustomization` is deleted |
| --- | --- |
| `MirrorPrune` | The default. Deletes the applied objects if `prune` is `true`, and keeps them if it is `false` |
| `Delete` | Always deletes the applied objects |
| `WaitForTermination` | Deletes them and waits until they are gone before the Flux object disappears |
| `Orphan` | Never deletes them; they stay as unmanaged objects |

`Orphan` is the safe choice when you move objects from one Flux `Kustomization` to another: delete the old one with `Orphan`, and the new one adopts the objects without downtime.

You can now follow objects through the inventory, predict what pruning deletes, and keep an object on purpose. Everything so far was about kustomize-controller. The open question is helm-controller, which handles drift in a different way.

## Common pitfalls

> [!WARNING]
> - **Leaving `prune: false` after a migration.** Every file removed from Git leaves an object behind, and nothing reports it.
> - **Expecting `prune: true` to clean up old leftovers.** Pruning only deletes objects on the inventory. Objects that dropped off it while pruning was off must be deleted by hand.
> - **Deleting a Flux `Kustomization` to "restart" it.** With the default policy and pruning on, that deletes the application too. Use `flux reconcile`, or `deletionPolicy: Orphan` when you really need to replace it.
> - **Pruning a namespace with the application.** A namespace in the same folder is pruned like any object, together with everything in it. Protect it with the `prune: disabled` annotation.
