# Deleting A Stage

Removing a file from Git deletes one object. Removing a whole Flux `Kustomization` can delete everything it applied. This part shows what happens in each case, so that you delete a stage on purpose and not by accident.

## The rule

A Flux `Kustomization` has a finalizer (a marker that makes the API server wait for the controller before it removes the object). When you delete the Flux `Kustomization` and `prune: true` is set, kustomize-controller first deletes every object in its inventory and then lets the Flux `Kustomization` go. The field `spec.deletionPolicy` changes this:

- `MirrorPrune` is the default. It follows `prune`: with `prune: true` the objects are deleted, with `prune: false` they stay.
- `Delete` deletes the objects, even when `prune: false`.
- `WaitForTermination` deletes the objects and waits until they are gone.
- `Orphan` never deletes the objects.

## Delete with and without the objects

Use the demo stage from the pruning experiments, or any stage you created. First delete it with the default policy:

<!-- astrona:playground:renew -->

```sh
flux get kustomizations
kubectl -n podinfo-staging get configmaps
flux delete kustomization demo --silent
kubectl -n podinfo-staging get configmaps
```

The ConfigMaps the stage applied are gone. Create the stage again with the orphan policy by saving this as `kustomization-demo.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: demo
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/demo
  prune: true
  targetNamespace: podinfo-staging
  deletionPolicy: Orphan
  sourceRef:
    kind: GitRepository
    name: fleet
```

Apply it, wait for the objects, and delete the stage:

```sh
kubectl apply -f kustomization-demo.yaml
flux reconcile kustomization demo --with-source
flux delete kustomization demo --silent
kubectl -n podinfo-staging get configmaps
```

The ConfigMaps are still there. They keep the owner labels of the deleted stage, but nothing owns them any more. Clean them up by hand, or apply them again from a new stage that adopts them: the next apply writes new labels.

## When the Flux Kustomization is stuck

If the namespace or the cluster the stage applies to is already gone, the finalizer can wait forever. Read the events, and fix the cause:

```sh
flux events --for Kustomization/demo
```

You can now delete a stage with or without its objects and know which policy decides it. This closes the module: the inventory says what a stage owns, pruning removes what left Git, a move uses two commits, and a deletion follows `deletionPolicy`.

## Common pitfalls

> [!WARNING]
> - **Deleting a stage that applies a namespace.** Deleting the namespace deletes everything inside it.
> - **Deleting the stage that applies the other stages.** Their objects go with it, and so do theirs.
> - **Assuming the policy is `Orphan`.** The default deletes the objects when `prune: true`.
> - **Leaving orphaned objects.** They have no owner, and no stage will clean them up.
