# What helm-controller Compares

Before you correct drift, you need to know what helm-controller calls drift. This part makes a manual change, shows that helm-controller ignores it by default, and then reads the report that `mode: warn` produces.

## The comparison

When drift detection is on, helm-controller compares each object of the release in the cluster with the manifest of the last release revision that it installed or upgraded. A field that differs is drift. Fields that the chart never set and that the API server defaults are not drift, because the comparison asks the API server for the result of applying the release manifest and compares that with the live object.

Without `spec.driftDetection`, helm-controller does not compare at all. It acts only when the chart, the version or the values change.

## A change nobody reports

Scale the production Deployment by hand and reconcile the release:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-production scale deployment podinfo --replicas=5
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo
```

The release is `Ready` and the Deployment still has 5 replicas. Nothing changed in the chart or the values, so helm-controller did nothing.

## Turn on reporting

Save this as `helmrelease-patch-warn.yaml`:

```yaml
spec:
  driftDetection:
    mode: warn
```

Apply it to the release and reconcile:

```sh
kubectl -n podinfo-production patch helmrelease podinfo --type=merge --patch-file helmrelease-patch-warn.yaml
flux reconcile helmrelease podinfo -n podinfo-production
```

Then read the conditions and the events:

```sh
kubectl -n podinfo-production get helmrelease podinfo \
  -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" "}{.reason}{"\n"}{end}'
flux events --for HelmRelease/podinfo -n podinfo-production
```

The condition `Drifted` has the status `True` and the reason `DriftDetected`. The events name the drifted object and field. The Deployment still has 5 replicas, because `warn` changes nothing.

## What the report is good for

A report shows manual changes before you decide what to do with them. Run `warn` first on a cluster where people edit things by hand. Each drifted field is either a mistake to correct or a field that another writer should own. The next part writes the rules for the second case.

You can now see what helm-controller calls drift and read it. The next part limits the comparison to the fields that matter.

## Common pitfalls

> [!WARNING]
> - **Expecting a `HelmRelease` to revert manual changes by default.** Without drift detection it never looks at the live objects.
> - **Reading `Ready True` as "no drift".** The release can be `Ready` and `Drifted` at the same time.
> - **Treating `warn` as a fix.** It only reports.
> - **Comparing against Git.** helm-controller compares against the last release, not against the repository.
