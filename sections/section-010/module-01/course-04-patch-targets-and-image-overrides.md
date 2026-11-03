# Patch Targets And Image Overrides

A patch is only as good as its target. A target that is too narrow changes one object and leaves its twin untouched, and a target that matches nothing changes nothing and reports no error. This part shows every way to select objects for a patch, and then adds the fields that change many objects at once without a patch: `commonMetadata`, `images`, `namePrefix` and `nameSuffix`.

## Select objects with `target`

Every item of `spec.patches` in a Flux `Kustomization` may carry a `target`. The target is a filter on the built objects, and the patch applies to each object that passes all of it. These fields are available:

| Field | What it matches |
| --- | --- |
| `group`, `version`, `kind` | The API group, version and kind of the object |
| `name` | The name of the object, as a regular expression that must match the whole name |
| `namespace` | The namespace of the object, as a regular expression that must match the whole namespace |
| `labelSelector` | A label selector, such as `app=podinfo` |
| `annotationSelector` | An annotation selector, such as `owner=platform` |

Two rules matter in practice. A target with several fields matches only objects that satisfy all of them. A target with no `name` matches every object of the kind, so one patch can change a whole group of objects, such as every Deployment with a given label. A patch with no `target` at all uses the `kind` and `name` written inside the patch itself, which is how a strategic merge patch often looks.

## Preview a build with all the fields

Clone the repository first. This needs the port-forward to Gitea to run in a second terminal.

```sh
git clone http://gitops:gitops-password@gitea.localtest.me:3000/gitops/fleet.git
cd fleet
```

Save this as `kustomization-podinfo-variants.yaml` inside the folder `fleet`, but do not commit it. It builds the base folder into the namespace `podinfo-staging`, selects the Deployment by label, sets the image tag, and adds a prefix and common metadata:

<!-- astrona:playground:renew -->

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-variants
  namespace: flux-system
spec:
  interval: 10m
  path: ./apps/podinfo/base
  prune: true
  targetNamespace: podinfo-staging
  namePrefix: canary-
  sourceRef:
    kind: GitRepository
    name: fleet
  commonMetadata:
    labels:
      owner: platform
    annotations:
      docs: https://example.com/runbooks/podinfo
  images:
    - name: ghcr.io/stefanprodan/podinfo
      newTag: 6.9.0
  patches:
    - patch: |
        - op: replace
          path: /spec/replicas
          value: 2
      target:
        kind: Deployment
        labelSelector: app=podinfo
```

Build it locally. The command needs no cluster state for the build itself, and `--dry-run` keeps it away from the API server:

```sh
flux build kustomization podinfo-variants \
  --path ./apps/podinfo/base \
  --kustomization-file kustomization-podinfo-variants.yaml \
  --dry-run
```

Read the output and look for four changes. The Deployment and the Service have names that start with `canary-`. Both carry the label `owner: platform` and the annotation `docs`. The container image ends in `:6.9.0`. The Deployment has `replicas: 2`.

## What each field does

**`commonMetadata`** adds labels and annotations to the metadata of every object. It sets metadata only. It does not touch the label selector of a Deployment or the labels of the pod template, so it never changes which pods a Service or a Deployment selects. That makes it safe to add after the first deploy. The Kustomize file has a `labels` field with the options `includeSelectors` and `includeTemplates` that can reach those places, and changing a selector of a running Deployment is rejected by Kubernetes, because that field is immutable.

**`images`** changes the image of every container that uses the image named in `name`. `newTag` changes the tag, `newName` changes the repository, and `digest` pins a digest. One entry covers every Deployment, StatefulSet and Job in the build that uses that image, so it is the right place to roll one environment to another version without a patch.

**`namePrefix`** and **`nameSuffix`** add text to the name of every object. Kustomize also updates the references between objects, such as a `configMapRef` that names a ConfigMap that got a prefix. The labels used as selectors do not change, so the Service `canary-podinfo` still selects pods with `app: podinfo`.

## Apply it and check the result

```sh
kubectl apply -f kustomization-podinfo-variants.yaml
flux reconcile kustomization podinfo-variants --with-source
kubectl -n podinfo-staging get deployment,service --show-labels
kubectl -n podinfo-staging get deployment canary-podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}{.spec.replicas}{"\n"}'
```

The namespace holds `canary-podinfo` as a Deployment and as a Service. The labels column shows `owner=platform` next to `app=podinfo`. The jsonpath prints the image with the tag `6.9.0` and the replica count `2`.

## Targets that match nothing

Now make the target too narrow. Change `labelSelector: app=podinfo` to `labelSelector: app=podinfo-canary` in the file, apply it again and reconcile:

```sh
kubectl apply -f kustomization-podinfo-variants.yaml
flux reconcile kustomization podinfo-variants
flux get kustomizations
kubectl -n podinfo-staging get deployment canary-podinfo
```

The Flux `Kustomization` stays `Ready`. No object has that label, so the patch changes nothing, and Flux reports no error. The Deployment is applied without the patch, so it goes back to 1 replica. Always check the built objects, as in the `flux build` step, and not only the `Ready` condition.

A regular expression in `name` is a second way to widen the target. A target such as `name: .*podinfo` with `kind: Deployment` matches `podinfo` and `canary-podinfo` alike. Because the expression must match the whole name, `name: podinfo` does not match `canary-podinfo`. If you combine a `namePrefix` with a patch that selects by `name`, select by label, by kind, or by a regular expression that allows for the prefix, and confirm the result with `flux build`.

## Common pitfalls

> [!WARNING]
> - **Expecting `name: podinfo` to match `canary-podinfo`.** `name` and `namespace` are regular expressions that must match the whole value.
> - **Using `commonMetadata` and expecting selectors to change.** It changes metadata only. A selector label needs the Kustomize `labels` field, and an existing Deployment cannot change its selector.
> - **Writing a label selector in the wrong form.** The form is `key=value`, with a comma between several pairs.
> - **Setting `images` with the wrong `name`.** It matches the image string without the tag. A different spelling of the repository matches nothing and changes nothing.
> - **Trusting `Ready` after a patch.** A target that matches no object is not an error. Check the built output.
