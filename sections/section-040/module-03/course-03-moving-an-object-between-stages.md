# Moving An Object Between Stages

A folder in Git is sometimes split in two: one team keeps its files, another team takes over a shared object. If you only move the file, the old stage sees a file that is gone and deletes the object. The new stage then creates it again, with a new UID (the unique identifier the API server gives each object). Workloads that depend on the object see a short outage. This part moves a ConfigMap between two stages so that the object is never deleted.

## The starting state

Two Flux `Kustomization` objects apply two folders of the same repository into the namespace `podinfo-staging`, both with `prune: true`. The Flux `Kustomization` `team-a` applies `./apps/team-a`, which holds the ConfigMap `shared-settings`. The Flux `Kustomization` `team-b` applies `./apps/team-b`. The inventory and the owner labels of `shared-settings` name `team-a`.

Why does a single commit that moves the file fail? When both stages reconcile in the same minute, `team-a` may prune first. Pruning deletes the object only when its owner labels still name `team-a`, and an apply by `team-b` changes those labels. The result depends on which stage runs first, and a bad order deletes the object. The fix is to make the order explicit with two commits.

## Two commits, one direction

The first commit adds the file to the new stage while the old stage still has it. Both stages now apply the same object. The second commit removes the file from the old stage.

<!-- astrona:playground:renew -->

Clone the repository and copy the file to the new folder:

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
cp apps/team-a/settings.yaml apps/team-b/settings.yaml
```

Open `apps/team-b/kustomization.yaml` and add `settings.yaml` to its `resources` list. Then commit and push the first step:

```sh
git add apps/team-b
git commit -m "Add shared-settings to team-b"
git push origin main
flux reconcile kustomization team-b --with-source
```

Before the second commit, read the owner labels and the UID:

```sh
kubectl -n podinfo-staging get configmap shared-settings --show-labels
kubectl -n podinfo-staging get configmap shared-settings -o jsonpath='{.metadata.uid}{"\n"}'
```

The labels now name `team-b`: its apply wrote them last. The UID is the one from before, because the API server updated the object and did not create it again. Record the UID, then remove the file from the old stage:

```sh
git rm apps/team-a/settings.yaml
```

Open `apps/team-a/kustomization.yaml` and remove `settings.yaml` from its `resources` list. Commit, push, and reconcile `team-a`:

```sh
git commit -am "Remove shared-settings from team-a"
git push origin main
flux reconcile kustomization team-a --with-source
kubectl -n podinfo-staging get configmap shared-settings -o jsonpath='{.metadata.uid}{"\n"}'
```

The UID is unchanged. `team-a` still has `shared-settings` in its inventory, but the object now carries the owner label of `team-b`, so pruning skips it. The stage `team-a` then drops the entry from its inventory.

## Checking the result

Read the inventory of both stages. `team-b` lists `shared-settings`, and `team-a` does not:

```sh
kubectl -n flux-system get kustomization team-a -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
kubectl -n flux-system get kustomization team-b -o jsonpath='{range .status.inventory.entries[*]}{.id}{"\n"}{end}'
```

You moved an object by giving it to the new stage first and taking it away from the old stage second. The optional extra safeguard is the annotation `kustomize.toolkit.fluxcd.io/prune: disabled` on the object during the move, as the earlier part showed, but it is not needed when the two commits are in this order. The next part removes a whole stage.

## Common pitfalls

> [!WARNING]
> - **Moving the file in one commit.** The result depends on which stage reconciles first, and a bad order deletes and recreates the object.
> - **Removing the file from the old stage first.** The old stage prunes the object, and it gets a new UID.
> - **Forgetting `kustomization.yaml`.** A file that is not in `resources` is not applied, and a listed file that is missing breaks the build.
> - **Moving between stages with different `targetNamespace` values.** The object would then be a different object in a different namespace.

## Your mission: Move An Object Between Stages Without Recreating It

You can now move an object from one Flux `Kustomization` to another and prove that its UID did not change. The mission gives you two stages and a ConfigMap owned by the first one. Move it to the second stage without deleting it, without turning pruning off and without suspending a stage.

Pause the playground, then start the lab:

```sh
astrona stop ats-096-playground-040-03
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-040/module-03/labs/lab-01
```

When the work is done, submit it:

```sh
astrona submit -c sections/section-040/module-03/labs/lab-01
```

Afterwards, remove the lab and resume the playground:

```sh
astrona destroy ats-096-lab-040-03
astrona start ats-096-playground-040-03
```
