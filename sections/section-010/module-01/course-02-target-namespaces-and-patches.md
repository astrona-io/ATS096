# Target Namespaces And Patches

Staging and production run the same application, but not in the same place and not in the same size. Production lives in its own namespace and runs two replicas, and the platform team wants a label on every production Deployment that says who owns it. This part makes those changes in the Flux `Kustomization` itself, so the base folder in Git stays the same for both environments.

## One base, two namespaces

The base folder `apps/podinfo/base` sets no namespace on its objects. That is on purpose: a base that names a namespace can only be deployed once. The field `targetNamespace` of a Flux `Kustomization` sets the namespace of every namespaced object it builds, and it overrides a namespace the folder already sets.

`targetNamespace` never creates the namespace. kustomize-controller applies objects into it, and if the namespace does not exist, the apply fails. In your playground the platform already created `podinfo-staging` and `podinfo-production`. On a real cluster you create the namespace in Git too, often in its own Flux `Kustomization` that runs first.

Two more fields change names and images without a patch. `namePrefix` and `nameSuffix` add text to the name of every object, which lets two copies share one namespace. `images` changes the image name, tag or digest of every container that uses a given image, for example `name: ghcr.io/stefanprodan/podinfo` with `newTag: 6.15.0`. This module does not need them, but you will meet them in real repositories.

## Two kinds of patch

A patch is a change applied to the built objects. The field `patches` of a Flux `Kustomization` is a list, and each item has two fields: `patch`, the change itself, and `target`, which objects it applies to. The `target` selects by `kind`, `name`, `namespace`, `labelSelector` or `annotationSelector`.

There are two kinds of patch, and both use the same field:

| Kind | What `patch` holds | Good for |
| --- | --- | --- |
| Strategic merge patch | A partial object: the fields you want, at their place in the object | Setting or changing values, such as `replicas` |
| JSON6902 patch | A list of operations (`add`, `replace`, `remove`, ...) on JSON paths | Precise changes, such as adding one label or removing one field |

The difference shows when a field holds a list. A strategic merge patch merges list items by a key, for example containers by `name`. A JSON6902 patch addresses one exact position, such as `/spec/template/spec/containers/0`.

## Deploy production with two patches

Create the production copy now. It uses the same base, the namespace `podinfo-production`, a strategic merge patch for the replica count, and a JSON6902 patch that adds the label `team: platform` to the Deployment.

<!-- astrona:playground:renew -->

Save this as `kustomization-podinfo-production.yaml`:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-production
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/base
  prune: true
  wait: true
  timeout: 2m
  targetNamespace: podinfo-production
  sourceRef:
    kind: GitRepository
    name: fleet
  patches:
    - patch: |
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: podinfo
        spec:
          replicas: 2
      target:
        kind: Deployment
        name: podinfo
    - patch: |
        - op: add
          path: /metadata/labels/team
          value: platform
      target:
        kind: Deployment
        name: podinfo
```

Apply it:

```sh
kubectl apply -f kustomization-podinfo-production.yaml
```

Then check the result:

```sh
flux get kustomizations
kubectl -n podinfo-production get deployment podinfo -L team
kubectl -n podinfo-staging get deployment podinfo -L team
```

Both rows of `flux get kustomizations` show `READY` as `True`. The production Deployment shows 2 ready replicas and the value `platform` in the `TEAM` column. The staging Deployment still has 1 replica and no `team` label. One folder in Git now produces two different Deployments, and the only place that says how they differ is the Flux `Kustomization` of each environment.

## When a patch does not match

A patch applies only to the objects its `target` selects. If the target names an object that the build does not contain, for example `name: podinfo-api`, the patch selects nothing and changes nothing. The build does not fail and the Flux `Kustomization` still becomes `Ready`. The result simply lacks the change.

That makes a wrong target one of the hardest mistakes to see. The safe habit is to check the result, not the object: run `flux build kustomization` with the right `--path` and look for the changed field, or read the live object with `kubectl get`. Try it now with the production copy; the build shows `replicas: 2` and the `team` label:

```sh
flux build kustomization podinfo-production --path ./apps/podinfo/base | grep -E 'replicas|team'
```

You can now deploy one base into several namespaces and change the built objects with both kinds of patch. You also know that a patch with a wrong target fails silently. The open question is values that differ per environment, such as a message or a label value, which patches can set but variables set more simply.

## Common pitfalls

> [!WARNING]
> - **Expecting `targetNamespace` to create the namespace.** It only sets the namespace on objects. If the namespace does not exist, the apply fails.
> - **A patch target that matches nothing.** The Flux `Kustomization` stays `Ready` and the change is simply missing. Check the built result, not only the `Ready` condition.
> - **Adding a key under a map that does not exist with JSON6902.** `add` on `/metadata/annotations/owner` fails when the object has no annotations at all. Add the whole map, or patch a map that exists, such as `labels`.
> - **Writing the patch YAML without the `|`.** `patch` holds a string. Without the block marker `|`, the YAML of the patch is read as fields of the Flux object and the apply is refused.
