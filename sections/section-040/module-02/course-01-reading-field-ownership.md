# Reading Field Ownership

The previous module printed the names of the field managers of an object. A name is not enough to decide who loses a fight: you need to know which fields each manager owns. This part prints that record for the staging Deployment and reads it, so that later parts can change it with a clear idea of what the change does.

## What the record contains

Every live object has `metadata.managedFields`, a list with one entry per manager and operation. Each entry has a `fieldsV1` map: a tree whose keys start with `f:` for a field. A leaf `{}` means the manager owns that field. `Apply` is the operation of a server-side apply, where the manager sent a full intent. `Update` is the operation of a plain write such as `kubectl scale` or `kubectl edit`, and the manager owns the fields that the write changed.

Print the record of the Deployment as YAML and look at the entry for kustomize-controller:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-staging get deployment podinfo --show-managed-fields -o yaml | sed -n '/managedFields/,/^  name:/p' | head -60
```

The entry for `kustomize-controller` has the operation `Apply` and the key `f:spec`, with `f:replicas` below it, because the file in Git sets `replicas: 1`. The entry for `kube-controller-manager` has `Update` and owns the status.

## Ask who owns one field

You can print only the fields of one manager with a JSONPath filter:

```sh
kubectl -n podinfo-staging get deployment podinfo --show-managed-fields \
  -o jsonpath='{.metadata.managedFields[?(@.manager=="kustomize-controller")].fieldsV1.f:spec}{"\n"}'
```

The output lists the spec fields that Flux owns: `f:replicas`, `f:selector`, `f:template` and so on. The fields that Flux does not list are not Flux's. If you read a field's name here, the next reconciliation can change it.

## Watch ownership move

Scale the Deployment by hand and print the managers again:

```sh
kubectl -n podinfo-staging scale deployment podinfo --replicas=3
kubectl -n podinfo-staging get deployment podinfo --show-managed-fields \
  -o jsonpath='{range .metadata.managedFields[*]}{.manager}{"  "}{.operation}{"\n"}{end}'
```

A manager named `kubectl` or `kubectl-scale` with the operation `Update` appears. That manager now owns `f:replicas`, and kustomize-controller shares the claim, because both sent a value. A field with more than one owner is shared, and the API server accepts the next apply only if the values agree or the applier forces the change. Flux forces, so the value of Git returns at the next reconciliation:

```sh
flux reconcile kustomization podinfo-staging
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The output is 1.

You can now read the ownership record and see how a hand-made change adds a second owner that Flux then overrules. The next part removes the claim instead of overruling the other writer.

## Common pitfalls

> [!WARNING]
> - **Reading only the manager names.** The fields under each name decide who wins.
> - **Calling `Update` a bug.** It is the normal record of a plain write.
> - **Expecting a shared field to be safe.** A shared field is exactly the one that Flux overrules.
> - **Forgetting `--show-managed-fields`.** `kubectl` hides the record unless you ask.
