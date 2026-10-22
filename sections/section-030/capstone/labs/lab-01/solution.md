# Solution: Repair Two Helm Releases

Work the task yourself first. Running `astrona submit -c sections/section-030/capstone/labs/lab-01` after a step tells you which checks pass, without telling you what is left.

The grader checks three things: staging installs through `chartRef` from the `OCIRepository` `podinfo-chart` at tag `6.15.0` and is `Ready`; production uses the `HelmRepository` `podinfo` in `flux-system`, takes its values from the Secret `podinfo-values` without `optional`, and is `Ready`; and each environment answers with its own message, production with 2 replicas.

## Step 1: Check the sources before the releases

A release can only install a chart that source-controller fetched, so start with the sources:

```sh
flux get sources oci -A
flux get sources helm -A
flux get helmreleases -A
```

The `HelmRepository` is `Ready`. The `OCIRepository` `podinfo-chart` is not: its message says the tag `6.15.9` was not found in the registry. Both releases are not ready.

## Step 2: Fix the OCI tag

The chart version is `6.15.0`. Run `kubectl -n podinfo-staging edit ocirepository podinfo-chart` and set:

```yaml
  ref:
    tag: 6.15.0
```

Then reconcile the source and the release:

```sh
flux reconcile source oci podinfo-chart -n podinfo-staging
flux reconcile helmrelease podinfo -n podinfo-staging
```

Both become `Ready`, and podinfo in staging answers `staging`.

## Step 3: Read why production does not install

```sh
flux events --for HelmRelease/podinfo -n podinfo-production
```

The events say helm-controller cannot find the `HelmRepository` `podinfo` in `podinfo-production`. The `sourceRef` has no `namespace`, so helm-controller looks in the release's own namespace. Run `kubectl -n podinfo-production edit helmrelease podinfo` and add it:

```yaml
      sourceRef:
        kind: HelmRepository
        name: podinfo
        namespace: flux-system
```

## Step 4: Read the values Secret's keys

Reconcile once more and read the events again:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
flux events --for HelmRelease/podinfo -n podinfo-production
kubectl -n podinfo-production get secret podinfo-values -o jsonpath='{.data}' | jq 'keys'
```

Now the error is about the values: helm-controller cannot find the key `values.yaml` in the Secret. The last command lists the Secret's keys without printing their values, and the only key is `values.yml`. The Secret is correct, so change the reference: run `kubectl -n podinfo-production edit helmrelease podinfo` and set the key:

```yaml
  valuesFrom:
    - kind: Secret
      name: podinfo-values
      valuesKey: values.yml
```

Then reconcile and prove it:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
flux get helmreleases -A
kubectl -n gitea exec deploy/tester -- sh -c 'curl -s http://podinfo.podinfo-production:9898 | jq -r .message'
```

Both releases are `Ready`. Production answers `production from Secret` and runs 2 replicas.

## Step 5: Submit

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

## Why the obvious shortcuts are wrong

| Shortcut | What happens |
| --- | --- |
| `optional: true` on the Secret | Production installs with the chart defaults: 1 replica and the default message |
| Rename the key in the Secret | The platform team owns it; the next update from them breaks production again |
| Switch staging to the `HelmRepository` | It works, but staging no longer tests the OCI registry, which is its purpose |
| Copy the `HelmRepository` into `podinfo-production` | A second source of the same charts now needs its own care |

## Common mistakes

- Debugging the release while its source is not ready.
- Printing the Secret's values to read its keys. `jsonpath='{.data}'` with `jq 'keys'` shows only the names.
- Expecting one reconcile to show all errors. Each fix reveals the next fault.
