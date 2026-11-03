# Sharing Fields With An Autoscaler

A horizontal autoscaler changes the replica count of a Deployment according to load. If helm-controller corrects drift on the same field, the two fight: the autoscaler sets 4, and the next reconciliation sets 2. This part reproduces the fight and ends it with an ignore rule on that one field.

## Reproduce the fight

Turn on correction with no ignore rule. Save this as `helmrelease-patch-enabled.yaml`:

```yaml
spec:
  driftDetection:
    mode: enabled
    ignore: null
```

Apply it, then play the autoscaler. The flag `--field-manager` records who wrote the value:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-production patch helmrelease podinfo --type=merge --patch-file helmrelease-patch-enabled.yaml
kubectl -n podinfo-production patch deployment podinfo --type=merge -p '{"spec":{"replicas":4}}' --field-manager=autoscaler
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The Deployment is back at 2 replicas. The autoscaler's value lasted until the next reconciliation.

## Leave the field to the other writer

Add the rule for `/spec/replicas` on Deployments, as in the previous part. Then write the autoscaler value again and reconcile:

```sh
kubectl -n podinfo-production patch helmrelease podinfo --type=merge \
  -p '{"spec":{"driftDetection":{"mode":"enabled","ignore":[{"paths":["/spec/replicas"],"target":{"kind":"Deployment"}}]}}}'
kubectl -n podinfo-production patch deployment podinfo --type=merge -p '{"spec":{"replicas":4}}' --field-manager=autoscaler
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The Deployment keeps 4 replicas.

## Everything else is still corrected

The rule only removes one field from the comparison. Change another field by hand and reconcile:

```sh
kubectl -n podinfo-production patch deployment podinfo --type=json \
  -p '[{"op":"replace","path":"/spec/template/spec/containers/0/resources/requests/cpu","value":"333m"}]'
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}{"\n"}'
```

The request returns to the value from the chart. The ignore rule did not hide it.

You can now let another writer own one field of a Helm release and keep correcting the rest. The next part compares this with the other options and their cost.

## Common pitfalls

> [!WARNING]
> - **Switching drift detection off to stop the fight.** Every other field loses its protection.
> - **Ignoring `/spec/replicas` while the chart still sets `replicaCount`.** The chart value applies at the next upgrade, which resets the count once.
> - **Two autoscalers on one Deployment.** They fight each other, ignore rule or not.
> - **Forgetting to test a second field.** Prove that correction still works elsewhere.

## Your mission: Let An Autoscaler Own Replicas In A Helm Release

You can now keep drift correction on and exclude one field from it. The mission gives you a release that corrects every field and asks you to leave only the replicas to another writer, without turning correction off.

Pause the playground, then start the lab:

```sh
astrona stop ats-096-playground-040-04
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-040/module-04/labs/lab-01
```

When the work is done, submit it:

```sh
astrona submit -c sections/section-040/module-04/labs/lab-01
```

Afterwards, remove the lab and resume the playground:

```sh
astrona destroy ats-096-lab-040-04
astrona start ats-096-playground-040-04
```
