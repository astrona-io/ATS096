# Conflicts And Forced Changes

Two writers can claim the same field. What happens depends on how each one writes. A plain write wins and shares ownership. A server-side apply with a different value is refused as a conflict, unless the applier forces it. This part creates a conflict on purpose, reads the error, and shows how Flux settles it each time.

## A conflict from another applier

Put `replicas` back into Git first, so that Flux owns the field. Restore the line in the clone and push:

<!-- astrona:playground:renew -->

```sh
cd fleet
git revert --no-edit HEAD
git push origin main
flux reconcile kustomization podinfo-staging --with-source
```

Now apply a partial Deployment with server-side apply and a manager name of your own. The object contains only the field you want to set:

```sh
kubectl apply --server-side --field-manager=autoscaler -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: podinfo-staging
spec:
  replicas: 4
YAML
```

The API server refuses it with an error that names the conflict: the field `.spec.replicas` is owned by `kustomize-controller`. A server-side apply that disagrees with the current owner is a conflict, and the change is not made. The error protects you from overwriting another team's field by accident.

## Taking the field on purpose

The flag `--force-conflicts` tells the API server to take the field over:

```sh
kubectl apply --server-side --force-conflicts --field-manager=autoscaler -f - <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: podinfo
  namespace: podinfo-staging
spec:
  replicas: 4
YAML
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The value is 4, and the field now belongs to `autoscaler`. Flux does not give up, though. kustomize-controller applies with force as well, so at the next reconciliation it takes the field back:

```sh
flux reconcile kustomization podinfo-staging
kubectl -n podinfo-staging get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The value is 1 again. Whoever applies last with force wins the field, and Flux applies on a schedule. So a second applier cannot hold a field that is in Git. Only the removal from Git in the previous part ends the contest.

## Immutable fields

Some fields cannot be changed after creation, for example the label selector of a Deployment. A change in Git to such a field makes the apply fail with an error that the field is immutable. Flux has two ways to handle it, both of which delete and recreate the object and so cause a short outage:

- The annotation `kustomize.toolkit.fluxcd.io/force: enabled` on one object in Git.
- The field `spec.force: true` on the Flux `Kustomization`, for every object it applies.

Prefer the annotation: it limits the recreation to the object that needs it, and it can be removed once the change has been made.

You can now explain a conflict, take a field by force, and predict that Flux takes it back. The last part compares the exceptions in order of how much they give away.

## Common pitfalls

> [!WARNING]
> - **Using `--force-conflicts` against Flux.** It wins until the next reconciliation and then loses.
> - **Setting `spec.force: true` to silence one error.** Every object of the stage can now be recreated.
> - **Leaving the `force` annotation in Git.** The next immutable change recreates the object again.
> - **Reading a conflict as a bug.** It is the API server telling you the field has an owner.
