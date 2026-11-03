# Upgrades And Definitions

An upgrade can fail in places an install cannot: a field that cannot change, a hook that hangs, a custom resource definition that Helm does not touch. This part covers the settings for CRDs, for a failed upgrade and for a forced run, and the two Flux commands that get a stuck release moving again.

## Custom resource definitions in a chart

Charts can ship CRDs in a `crds` folder. Helm installs them with the first install and never changes or deletes them afterwards. Flux adds a policy for each action:

| Field | Values | Default |
| --- | --- | --- |
| `spec.install.crds` | `Skip`, `Create`, `CreateReplace` | `Create` |
| `spec.upgrade.crds` | `Skip`, `Create`, `CreateReplace` | `Skip` |

`Create` creates missing definitions and leaves existing ones. `CreateReplace` also replaces definitions that exist, so an upgrade of the chart updates its CRDs. `Skip` does nothing. Because the default for upgrades is `Skip`, a chart upgrade does not update its CRDs unless you ask:

```yaml
spec:
  install:
    crds: CreateReplace
  upgrade:
    crds: CreateReplace
```

Replacing a definition can remove fields from objects that use it, so use `CreateReplace` when you have read the changes of the chart.

## A failed upgrade

When an upgrade fails, the settings from the module on remediation decide whether Flux retries or rolls back. Two more fields change what the failure leaves behind:

- `upgrade.cleanupOnFail: true` deletes objects that the failed upgrade created. Without it, they stay and can block the next attempt.
- `upgrade.force: true` replaces objects instead of patching them. It recreates objects that cannot be patched, such as a Service with a changed immutable field. It causes a short outage for those objects.

`upgrade.preserveValues: true` reuses the values of the last release as a base for the new one. Keep it off for GitOps: the values should come from the object in Git and nowhere else.

## Getting a release unstuck

A release that ran out of retries stays failed until its spec changes. Two commands help without a commit:

<!-- astrona:playground:renew -->

```sh
flux reconcile helmrelease podinfo -n podinfo-staging --reset
flux reconcile helmrelease podinfo -n podinfo-staging --force
```

`--reset` clears the failure count so that the retries start from zero. `--force` makes helm-controller run an install or an upgrade even when nothing in the spec changed. Use `--reset` when the cause is fixed and you want to try again, and `--force` when the cluster has drifted from what Helm believes and you want a fresh run. Both are one-off requests and change nothing in Git.

## A release that Helm keeps in a pending state

If helm-controller is stopped in the middle of an action, for example when the controller Pod restarts, Helm can keep the release in a status such as `pending-upgrade`, and later actions fail because another operation is in progress. helm-controller checks for this at the start of a run and recovers the release when it can. If the status remains, read it with the Secret listing from the earlier part, and run `--reset` once the cause is gone.

You can now choose how CRDs, failed upgrades and forced runs are handled. The last part covers the end of the life of a release.

## Common pitfalls

> [!WARNING]
> - **Expecting CRDs to update with the chart.** The default for upgrades is `Skip`.
> - **`CreateReplace` without reading the chart changes.** A definition can lose fields.
> - **`upgrade.force` as a habit.** It recreates objects and causes outages.
> - **Using `--force` for a failing chart.** It runs the same failing action again.
