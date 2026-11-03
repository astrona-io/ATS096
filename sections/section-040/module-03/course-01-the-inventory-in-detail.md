# The Inventory In Detail

Pruning is only as good as the record it works from. This part reads that record for the staging stage, connects each entry to the live object, and shows the labels that mark an object as owned by a stage.

## The record

After a successful reconciliation, kustomize-controller writes the list of applied objects to `status.inventory.entries` of the Flux `Kustomization`. Each entry has an `id` and a version:

```sh
kubectl -n flux-system get kustomization podinfo-staging -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
```

An id has four parts joined by underscores: the namespace, the name, the group and the kind. For a Deployment it looks like `podinfo-staging_podinfo_apps_Deployment`. For a core object such as a Service the group is empty, so the id has two underscores in a row.

## The same list as a tree

`flux tree` shows the inventory as a tree, with the objects the Deployment created below it:

<!-- astrona:playground:renew -->

```sh
flux tree kustomization podinfo-staging
```

The first level is the inventory. The levels below are owned by Kubernetes controllers and are not part of the inventory, so Flux never prunes them: they go away when their parent goes away.

## The labels on an object

Each object that Flux applies carries two labels:

```sh
kubectl -n podinfo-staging get deployment podinfo --show-labels
```

The labels `kustomize.toolkit.fluxcd.io/name` and `kustomize.toolkit.fluxcd.io/namespace` name the Flux `Kustomization` that applied it. They are written at every apply. They answer the question "whose is this?" from the object itself, without reading any Flux object.

## Why both exist

The inventory says what a stage applied last time. The labels say whom an object belongs to now. Pruning uses both: it starts from the inventory, and it deletes an object only when the labels on it still name this stage. When another stage has taken the object over, the labels name that stage, and the old stage skips it. The next parts rely on this rule.

You can now read what a stage owns, from the stage and from the object. The next part states exactly what pruning removes.

## Common pitfalls

> [!WARNING]
> - **Reading the labels as a promise.** They show the last apply, not the right to apply.
> - **Looking for Pods in the inventory.** Only applied objects are listed, not the objects their controllers create.
> - **Editing the inventory by hand.** The next reconciliation overwrites it.
> - **Reading an empty `status.inventory`.** The stage has not applied successfully yet.
