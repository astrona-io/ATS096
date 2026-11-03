# Images, Replicas And Labels

Most overlay changes are small and repeat in every project: use another image tag, run more replicas, add a label to everything. Writing a patch for each of them works, but the Kustomize file has dedicated fields that say the same thing in fewer lines and can be read at a glance. This part walks through those fields, builds them locally, and shows where the Flux `Kustomization` has matching fields of its own.

## Transformers of the Kustomize file

A **transformer** is a field of the Kustomize file that changes every object it matches after the files are loaded. You already met two: `namespace` and `replicas`. Three more cover most real overlays:

| Field | What it changes |
| --- | --- |
| `images` | The name, tag or digest of every container image that matches `name`, in every Deployment, StatefulSet, Job and similar object |
| `labels` | Adds labels to every object, and with `includeSelectors: true` also to selectors |
| `namePrefix`, `nameSuffix` | Adds text to the name of every object and updates the references to it |

The `images` field is the one that matters most for delivery. Each entry matches an image by the name it has in the base, without the tag. It sets `newName`, `newTag` or `digest`. For example, this entry changes the tag and leaves the registry and repository alone:

```yaml
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.15.0
```

The base keeps a working default image, and each overlay chooses the version for its environment. A promotion from staging to production then becomes a one-line change in the production overlay.

## Try the transformers on staging

Add the three fields to the staging overlay in your clone, build it, and read the result. In your clone in the folder `fleet`, open `apps/podinfo/overlays/staging/kustomization.yaml` and replace its content with this:

<!-- astrona:playground:renew -->

```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: podinfo-staging
resources:
  - ../../base
  - configmap.yaml
replicas:
  - name: podinfo
    count: 1
images:
  - name: ghcr.io/stefanprodan/podinfo
    newTag: 6.15.0
labels:
  - pairs:
      environment: staging
    includeSelectors: false
```

Then build it locally:

```sh
kubectl kustomize apps/podinfo/overlays/staging
```

The built Deployment keeps the image `ghcr.io/stefanprodan/podinfo:6.15.0`. Every object, the Deployment, the Service and the ConfigMap, now carries the label `environment: staging` under `metadata.labels`. The Deployment pod template has no new label, and the selectors are unchanged.

That last detail is the reason for `includeSelectors: false`. The `spec.selector` of a Deployment cannot change after it is created. If you add a label with `includeSelectors: true` to an application that already runs, the new selector no longer matches the old one and the apply fails. With `false`, the label goes on the object metadata only, which is safe for a live cluster. The Kustomize field `includeTemplates` is the third switch: it adds the label to pod templates, so the pods carry it too.

## Where the Flux Kustomization has its own fields

kustomize-controller applies its own fields after the build, and some of them match the transformers above. The Flux `Kustomization` has `images` with the same shape, `namePrefix` and `nameSuffix`, and `commonMetadata`, which adds labels and annotations to every applied object without touching selectors. It also has `targetNamespace`, which overrides the namespace.

Which one to use depends on where the decision belongs. A value that every user of the overlay must get, such as the image tag of production, goes in the Kustomize file in Git, next to the overlay. A value that only one cluster needs, such as an extra annotation for a cluster-wide tool, can go in the Flux `Kustomization` of that cluster. When both set the same field, the Flux field is applied later, so it wins.

## Commit the overlay and let Flux apply it

Commit the change and push it. The Flux `Kustomization` `podinfo-staging` reads the new commit:

```sh
git add apps/podinfo/overlays/staging/kustomization.yaml
git commit -m "Pin the staging image and add a label"
git push origin main
flux reconcile source git fleet
flux reconcile kustomization podinfo-staging
```

Then check the result:

```sh
kubectl -n podinfo-staging get deployment podinfo -L environment
kubectl -n podinfo-staging get service podinfo -L environment
```

Both objects show `staging` in the `ENVIRONMENT` column, and the Deployment is still available. The image tag was already `6.15.0`, so the pod did not restart: the Deployment spec did not change. That is how a no-op change should look.

You can now change images, replica counts, namespaces, names and labels from the Kustomize file, and you know which labels are safe on a running workload. The open question is configuration that changes often, such as a message in a ConfigMap. A plain ConfigMap file changes the data but not the Deployment, so the pods do not notice. Generators solve that.

## Common pitfalls

> [!WARNING]
> - **Matching `images` by the full name with the tag.** The `name` is the image name without the tag. `ghcr.io/stefanprodan/podinfo:6.15.0` does not match anything.
> - **Adding a label with `includeSelectors: true` to a running Deployment.** The selector of a Deployment is immutable, so the apply fails. Use `includeSelectors: false`.
> - **Using `namePrefix` on part of an application.** Kustomize renames the objects it builds, but not objects outside the build that refer to them by name.
> - **Expecting the label to be on the pods.** Pod labels come from the pod template. Use `includeTemplates` or a patch for that.
