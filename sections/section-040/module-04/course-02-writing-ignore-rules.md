# Writing Ignore Rules

Some fields must be allowed to differ from the release. A rule that is too wide hides real drift, and a rule that is too narrow still triggers corrections. This part writes rules with a path and a target, and checks that each one does what you meant.

## The shape of a rule

`spec.driftDetection.ignore` is a list. Each entry has `paths`, a list of JSON Pointers (a way to name one field by its path, with `/` between the parts and list positions as numbers), and an optional `target` that selects objects. The target accepts `kind`, `name`, `namespace`, `labelSelector` and `annotationSelector`. Without a target, the rule applies to every object of the release that has the path.

Find the exact path before you write it. Print the live object and count the keys:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-production get deployment podinfo -o json | jq '.spec | keys'
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].name}{"\n"}'
```

The replica count is `/spec/replicas`. The resources of the first container are `/spec/template/spec/containers/0/resources`. A key with a `/` in it is written with `~1`, and a `~` is written `~0`.

## A rule with a target

Save this as `helmrelease-patch-ignore.yaml`:

```yaml
spec:
  driftDetection:
    mode: enabled
    ignore:
      - paths: ["/spec/replicas"]
        target:
          kind: Deployment
          name: podinfo
```

Apply it, then scale by hand and reconcile:

```sh
kubectl -n podinfo-production patch helmrelease podinfo --type=merge --patch-file helmrelease-patch-ignore.yaml
kubectl -n podinfo-production scale deployment podinfo --replicas=4
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The Deployment keeps 4 replicas. The rule matched the object by kind and name, and the path named the field.

## A rule that matches nothing

A typo in the path or a name that does not exist produces no error. The rule simply never matches, and the drift is corrected as before. After you write a rule, always change the field by hand, reconcile, and read the field. Do not trust a rule you did not test.

You can now write a rule that names one field on one object. The next part shows why this is the right tool for a field that another controller writes.

## Common pitfalls

> [!WARNING]
> - **A rule without a `target`.** It applies to every object that has the path.
> - **Ignoring a whole object subtree.** `/spec/template` hides image and environment drift too.
> - **A typo in a JSON Pointer.** It ignores nothing and gives no error.
> - **Replacing the list when patching.** A merge patch replaces the whole `ignore` list. Include every rule you want to keep.
