# Failed Upgrades, Remediation And Rollback

Sooner or later an upgrade fails: an image tag that does not exist, a value the chart rejects, a pod that never becomes ready. Run by hand, `helm upgrade` leaves the release in a failed state and someone has to notice and run `helm rollback`. helm-controller can do that itself. This part configures what it does after a failure, pushes an upgrade that cannot work, and reads every trace the failure leaves behind.

## What remediation means

**Remediation** is what helm-controller does after a failed install or upgrade. It has separate settings for each:

| Field | Default | What it does |
| --- | --- | --- |
| `install.remediation.retries` | `0` | How many times to try a failed install again; a negative value means no limit |
| `upgrade.remediation.retries` | `0` | How many times to try a failed upgrade again |
| `upgrade.remediation.strategy` | `rollback` | What to do after a failed upgrade: `rollback` to the last good revision, or `uninstall` the release |
| `upgrade.remediation.remediateLastFailure` | `false`, or `true` when `retries` is above `0` | Whether to remediate after the last failed try too |
| `timeout` | `5m0s` | How long helm-controller waits for the release's resources before it calls the install or upgrade failed |

An upgrade counts as failed when the chart cannot render, when the API server refuses an object, or when the new pods are not ready within `timeout`. With `retries: 1` and the strategy `rollback`, helm-controller tries the upgrade, rolls back when it fails, tries once more, and rolls back again. When the retries run out, it stops trying: the `HelmRelease` gets the condition `Stalled` with the reason `RetriesExceeded`, and it waits for a change.

That change is a new configuration. The failure counters reset when the values, the chart version or the rest of the spec change, so the way out of a stalled release is to fix what made it fail.

## Prepare production for a bad upgrade

Give the production release one retry, a rollback strategy and a short timeout, so the failure shows within minutes. In the same edit, break the upgrade with an image tag that does not exist.

<!-- astrona:playground:renew -->

Run `kubectl -n podinfo-production edit helmrelease podinfo`, add these fields under `spec`:

```yaml
  timeout: 1m
  upgrade:
    remediation:
      retries: 1
      strategy: rollback
```

and change the inline values so they read:

```yaml
  values:
    replicaCount: 2
    image:
      tag: 0.0.0-missing
```

Save and close the editor. The values changed, so the next reconciliation is an upgrade, and this upgrade cannot work: no image with that tag exists.

## Watch the upgrade fail and roll back

Ask helm-controller to reconcile, and follow the release while it works:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
flux get helmreleases -n podinfo-production
flux events --for HelmRelease/podinfo -n podinfo-production
```

The reconcile command reports a failure after a few minutes. The events tell the story in order: the upgrade started, the new pods could not pull the image, the upgrade failed at the timeout, helm-controller rolled back, tried the upgrade once more, and rolled back again. The release ends not ready, with the condition `Stalled`. Throughout, podinfo kept answering: the Deployment never replaced its working pods with pods that could not start.

Helm's storage holds the whole record:

```sh
kubectl -n podinfo-production get secrets -l owner=helm -L version,status
kubectl -n podinfo-production get deployment podinfo -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}'
```

The storage now has several revisions. The upgrades have the status `failed`, the rollbacks created new revisions, and the newest one is `deployed`. The Deployment runs the image with the tag `6.15.0` again: the rollback put back the last good release.

## Recover with a fix

A stalled release does nothing until its configuration changes. Remove the `image` block from the values with `kubectl -n podinfo-production edit helmrelease podinfo`, then reconcile:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
flux get helmreleases -n podinfo-production
```

The values changed, so the counters reset and helm-controller runs a normal upgrade. The release is `Ready` again. The failed revisions stay in Helm's storage, which is useful: they are the proof that the failure happened and that remediation handled it.

Two related settings are worth knowing. `test.enable: true` runs the chart's tests after each install or upgrade, and a failed test counts as a failed release unless `test.ignoreFailures` is set. And the strategy `uninstall` removes the release after a failed upgrade, which fits stateless tools that a fresh install fixes, but never fits a database.

You can now make helm-controller roll back a failed upgrade, read the failure in the events and in Helm's storage, and get a stalled release going again with a fix. That is what the graded lab asks you to do, for two environments with their own values.

## Common pitfalls

> [!WARNING]
> - **No remediation at all.** With the default `retries: 0` and no `remediateLastFailure`, a failed upgrade is not rolled back. The release stays failed until someone fixes it.
> - **Reading `Stalled` as broken beyond repair.** It means helm-controller stopped retrying. Change the values or the chart version and it tries again.
> - **A timeout shorter than a normal rollout.** Every slow but healthy upgrade then fails and rolls back.
> - **Fixing the release with `helm rollback` by hand.** helm-controller tries its own spec again at the next reconciliation. Fix the `HelmRelease` instead.

## Your mission: Override A Chart Per Environment And Survive A Bad Upgrade

You can now install a chart into several environments with their own values, and let helm-controller roll back a failed upgrade. The graded lab gives you a cluster with the chart repository and two empty namespaces, and asks you to install podinfo into both with values from a ConfigMap per environment, then survive a bad production upgrade.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-096-playground-030-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-030/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-030/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-096-lab-030-01
astrona start ats-096-playground-030-01
```
