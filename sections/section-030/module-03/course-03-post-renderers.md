# Post-Renderers

A chart exposes only the values its author thought of. If you need an annotation on one object, or a different image registry, and the chart has no value for it, you can still change the result. A post-renderer rewrites the rendered manifests before Helm installs them. Flux supports Kustomize as a post-renderer, with patches and image overrides. This part adds one to a release and proves the effect.

## Where it acts

The order is: values are merged, the chart is rendered, the post-renderers run on the rendered YAML, and the result is installed. The patch therefore sees real objects with their final names, not templates.

The field is `spec.postRenderers`, a list. Each entry has a `kustomize` block with `patches` and `images`.

## A patch

A patch names its target and gives a change. The target selects objects by `kind` and `name`, and more selectors exist. The change is a strategic merge patch or a JSON patch as a string. Add an annotation to the Deployment of podinfo:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"postRenderers":[{"kustomize":{"patches":[{"target":{"kind":"Deployment","name":"podinfo"},"patch":"apiVersion: apps/v1\nkind: Deployment\nmetadata:\n  name: podinfo\n  annotations:\n    owner: platform\n"}]}}]}}'
flux reconcile helmrelease podinfo -n podinfo-staging
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.metadata.annotations.owner}{"\n"}'
```

The output is `platform`. The chart has no value for this annotation, and the post-renderer added it.

The same release as a file, easier to read:

```yaml
spec:
  postRenderers:
    - kustomize:
        patches:
          - target:
              kind: Deployment
              name: podinfo
            patch: |
              apiVersion: apps/v1
              kind: Deployment
              metadata:
                name: podinfo
                annotations:
                  owner: platform
```

## Images

`images` rewrites the images used in the rendered manifests, which is how you point a chart at an internal registry:

```yaml
spec:
  postRenderers:
    - kustomize:
        images:
          - name: ghcr.io/stefanprodan/podinfo
            newName: registry.example.com/mirror/podinfo
```

This example is not applied in the playground: the mirror does not exist. `newTag` and `digest` work in the same way.

## The cost

A post-renderer hides a difference between the chart and the cluster. The next person who reads the chart and the values will not see why an object is different. Prefer a chart value when one exists, and keep each patch small and named in a comment or in the commit message.

You can now change what a chart renders without forking the chart. The mission combines this with a value from a ConfigMap.

## Common pitfalls

> [!WARNING]
> - **A target that matches nothing.** The patch is silently not applied. Check `kind` and `name` against the rendered object.
> - **Patching what a value could set.** Use the value when the chart has one.
> - **A patch that changes immutable fields.** The upgrade fails.
> - **Forgetting `apiVersion`, `kind` and `name` in a strategic merge patch.** The patch cannot find its object.

## Your mission: Take Values From A ConfigMap And Patch The Output

You can now read values from a ConfigMap and rewrite rendered objects. The mission asks for both on one release.

Pause the playground first:

```sh
astrona stop ats-096-playground-030-03
```

Start the lab and submit when you are done:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-030/module-03/labs/lab-01
astrona submit -c sections/section-030/module-03/labs/lab-01
```

When the lab is done, remove it and start the playground again:

```sh
astrona destroy ats-096-lab-030-03
astrona start ats-096-playground-030-03
```
