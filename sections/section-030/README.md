# Section 030: Deploying Helm Charts With HelmRelease

Many applications ship as a Helm chart: a package of Kubernetes templates plus a file of default values. Flux installs and upgrades charts with its own controller, helm-controller, and its own object, the `HelmRelease`. You describe the chart and the values, and helm-controller runs the install or the upgrade, keeps the release history, and decides what to do when an upgrade fails.

This section takes one chart, podinfo `6.15.0`, through the whole cycle: fetching it from a chart repository and from an OCI registry, installing it into two environments with different values, and surviving an upgrade that cannot work.

**Topic covered:** Helm delivery and remediation

## What you will learn

- The objects behind a Helm install in Flux: `HelmRepository`, `HelmChart` and `HelmRelease`, and which controller handles each one.
- Reading a release: `flux get helmreleases`, the `HelmRelease` status history, and Helm's own storage Secrets.
- Giving a release its values with `values`, and with `valuesFrom` from ConfigMaps and Secrets, including `valuesKey` and `targetPath`.
- Installing from an OCI registry with an `OCIRepository` and `chartRef`.
- What helm-controller does after a failed install or upgrade: retries, rollback, uninstall and the `Stalled` condition.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Deploy Helm Charts With HelmRelease

The playground holds Flux and empty namespaces for staging and production. It needs outbound internet, because the chart comes from `stefanprodan.github.io` and `ghcr.io`.

1. From HelmRepository To HelmRelease
2. Values, valuesFrom And OCI Chart Sources
3. Failed Upgrades, Remediation And Rollback, followed by the lab **Override A Chart Per Environment And Survive A Bad Upgrade**
4. Summary

## Section capstone: Repair Two Helm Releases

The capstone is one graded scenario that uses everything in the module. Staging installs the chart from an OCI registry, production from a chart repository with its values in a Secret, and neither one installs. Each fault is a reference that points at something that does not exist. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-030/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-096-capstone-030
```
