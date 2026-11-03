# Choosing A Drift Policy

Each setting trades safety against freedom. This part compares the options for a Helm release, adds the second layer that watches the `HelmRelease` object itself, and gives a rule for choosing.

## Three settings

With no `driftDetection`, helm-controller never compares. Manual changes last until the next upgrade. With `mode: warn`, it compares and reports through the `Drifted` condition and events, and changes nothing. With `mode: enabled`, it compares and applies the release manifest again to the objects that differ. Ignore rules apply to `warn` and to `enabled`.

How often it happens: helm-controller compares on each reconciliation of the release, so a manual change lasts at most the `interval` of the `HelmRelease`, or less when you run `flux reconcile`.

## The release object is a second layer

The `HelmRelease` is itself an object that someone may edit. If a Flux `Kustomization` applies it from Git, kustomize-controller corrects the `HelmRelease` the same way it corrects a Deployment: a hand-made change to its spec is reverted at the next reconciliation. If you applied it with `kubectl apply` from a file, as in this course, nothing puts it back. Check which one applies your release:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-production get helmrelease podinfo --show-labels
```

Labels such as `kustomize.toolkit.fluxcd.io/name` show that a Flux `Kustomization` owns the object. No such label means nobody does.

## A rule of thumb

Use `warn` first when you do not know what people change. Move to `enabled` when the reports show mistakes only. Add one ignore rule per field that another writer owns, and name the object in the target. Do not use `enabled` without rules on a Deployment with an autoscaler.

You can now pick a drift policy for a release and say what keeps the release object itself in line. This closes the module: helm-controller compares against the last release, ignore rules remove single fields, and another writer owns what you leave out.

## Common pitfalls

> [!WARNING]
> - **Assuming Git protects the release.** Only a Flux `Kustomization` that applies the `HelmRelease` does.
> - **Using `enabled` without testing.** Start with `warn` on a busy cluster.
> - **One broad rule for everything.** Every ignored field is a field nobody guarantees.
> - **Expecting an instant correction.** It happens at the next reconciliation.
