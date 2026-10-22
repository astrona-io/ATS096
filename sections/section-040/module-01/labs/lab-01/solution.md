# Solution: Make Helm Correct Drift Without Touching Tuned Fields

Work the task yourself first. Running `astrona submit -c sections/section-040/module-01/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: drift detection is `enabled` and its ignore rules cover only the container resources of the Deployment; a manual scale to 5 is reverted to 2 after a reconciliation; and the CPU request of `50m` survives that reconciliation.

## Step 1: Confirm that drift is not corrected today

```sh
kubectl -n podinfo-production scale deployment podinfo --replicas=5
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo
```

The release reconciles and the Deployment keeps 5 replicas: without drift detection, helm-controller only acts when the chart or the values change.

## Step 2: Find the path of the tuned field

```sh
kubectl -n podinfo-production get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].name}{" "}{.spec.template.spec.containers[0].resources}{"\n"}'
```

The first container is `podinfo`, and its resources hold the CPU request `50m`. As a JSON Pointer, the resources of the first container are `/spec/template/spec/containers/0/resources`.

## Step 3: Turn on drift correction with one ignore rule

Run `kubectl -n podinfo-production edit helmrelease podinfo` and add this block under `spec`:

```yaml
  driftDetection:
    mode: enabled
    ignore:
      - paths: ["/spec/template/spec/containers/0/resources"]
        target:
          kind: Deployment
```

`mode: enabled` makes helm-controller correct drift; `warn` would only report it. The `target` limits the rule to the Deployment. A narrower path, `/spec/template/spec/containers/0/resources/requests/cpu`, is just as correct.

## Step 4: Prove both halves

```sh
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo
kubectl -n podinfo-production get deployment podinfo \
  -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}{"\n"}'
```

The Deployment is back at 2 replicas, and the CPU request is still `50m`.

## Step 5: Submit

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `mode: enabled` without an ignore rule | The scale is reverted, and so is the tuned CPU request: back to the chart's default |
| `mode: warn` | Drift is reported, and the Deployment keeps 5 replicas |
| Scale back by hand | It works once; the next manual scale stays again |
| Ignore `/spec` | Nothing is corrected at all |

## Common mistakes

- A JSON Pointer with dots instead of slashes, which matches nothing.
- An ignore rule without `target`, which ignores the path on every object of the release.
- Checking the replica count before reconciling.
