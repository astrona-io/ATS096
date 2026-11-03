# Solution: Let An Autoscaler Own Replicas In A Helm Release

Work the task yourself first. Running `astrona submit -c sections/section-040/module-04/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: the ignore rule covers only `/spec/replicas` on Deployments with the mode still `enabled`; 4 replicas written by another field manager survive a reconciliation; and a hand-made change to the CPU request is put back.

## Step 1: Read the release

```sh
kubectl -n podinfo-production get helmrelease podinfo -o jsonpath='{.spec.driftDetection}{"\n"}'
```

The mode is `enabled` and there is no `ignore` list.

## Step 2: Add the ignore rule

Save this as `helmrelease-patch.yaml`:

```yaml
spec:
  driftDetection:
    mode: enabled
    ignore:
      - paths: ["/spec/replicas"]
        target:
          kind: Deployment
```

Apply it to the release:

```sh
kubectl -n podinfo-production patch helmrelease podinfo --type=merge --patch-file helmrelease-patch.yaml
flux reconcile helmrelease podinfo -n podinfo-production
```

## Step 3: Prove it

Play the autoscaler, reconcile, and read the replicas. Then change the CPU request, reconcile, and read it again:

```sh
kubectl -n podinfo-production patch deployment podinfo --type=merge -p '{"spec":{"replicas":4}}' --field-manager=autoscaler
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.replicas}{"\n"}'
```

The Deployment keeps 4 replicas. A change to any other field is still reverted.

## Step 4: Submit

```sh
astrona submit -c sections/section-040/module-04/labs/lab-01
```
