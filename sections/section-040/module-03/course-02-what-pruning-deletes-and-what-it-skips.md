# What Pruning Deletes And What It Skips

Pruning runs after a successful apply. It compares the inventory of the last run with the objects of this run and deletes the difference. This part adds an object to a new stage, removes it, and then protects an object from the same removal with an annotation.

## A stage for experiments

Create a folder with two ConfigMaps and a Flux `Kustomization` for it. Clone the repository first:

<!-- astrona:playground:renew -->

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
mkdir -p apps/demo
```

Save this as `apps/demo/kustomization.yaml`:

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - one.yaml
  - two.yaml
```

Save this as `apps/demo/one.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-one
data:
  key: one
```

Save this as `apps/demo/two.yaml`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: demo-two
data:
  key: two
```

Commit, push, and create the stage:

```sh
git add apps/demo
git commit -m "Add the demo folder"
git push origin main
flux create kustomization demo --source=GitRepository/fleet --path=./apps/demo --prune=true --target-namespace=podinfo-staging --interval=10m
flux get kustomizations
kubectl -n podinfo-staging get configmaps
```

Both ConfigMaps exist. Remove the second one from Git:

```sh
git rm apps/demo/two.yaml
sed -i.bak '/two.yaml/d' apps/demo/kustomization.yaml
rm apps/demo/kustomization.yaml.bak
git commit -am "Remove demo-two"
git push origin main
flux reconcile kustomization demo --with-source
kubectl -n podinfo-staging get configmaps
```

`demo-two` is gone. It was in the last inventory and is not in the new build.

## What pruning never deletes

Pruning does not delete:

- An object that was never in the inventory, for example one created by hand with the same name.
- An object whose owner labels name another stage.
- An object with the annotation `kustomize.toolkit.fluxcd.io/prune: disabled`.
- Anything when `prune: false`.

Try the annotation. Add it to `one.yaml` in Git and push:

```sh
sed -i.bak 's/^  name: demo-one$/  name: demo-one\n  annotations:\n    kustomize.toolkit.fluxcd.io\/prune: disabled/' apps/demo/one.yaml
rm apps/demo/one.yaml.bak
git commit -am "Protect demo-one from pruning"
git push origin main
flux reconcile kustomization demo --with-source
```

Then remove `one.yaml` from the folder and from the list in `kustomization.yaml`, push, and reconcile. `demo-one` stays in the cluster, because the annotation tells the stage not to delete it. The object is no longer in the inventory and nothing in Git describes it: it is left behind on purpose. Delete it by hand when the reason is gone:

```sh
kubectl -n podinfo-staging delete configmap demo-one
```

You can now state what pruning removes and protect one object. The next part uses the label rule for a move.

## Common pitfalls

> [!WARNING]
> - **Using `prune: disabled` as a permanent home.** The object is no longer described anywhere. Use it for a short move or a deliberate keep.
> - **Expecting pruning to remove objects created by hand.** Only the inventory is pruned.
> - **Turning `prune` off to avoid a deletion.** Every removal stops being cleaned up.
> - **Forgetting the protected object.** It stays after the file is gone.
