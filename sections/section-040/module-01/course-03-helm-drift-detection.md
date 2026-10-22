# Drift Detection In helm-controller

helm-controller works like the `helm` command: it installs or upgrades a release when the chart or the values change, and otherwise leaves the objects alone. So a manual change to an object of a Helm release stays, through every reconciliation, until the next upgrade. This part proves that, then turns on drift detection, first to report and then to correct, with one field excluded on purpose.

## A manual change that stays

Production runs 2 replicas from the chart's values. Scale it by hand and ask helm-controller to reconcile:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-production scale deployment podinfo --replicas=5
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo
```

The release reconciles and stays `Ready`, and the Deployment still has 5 replicas. Neither the chart nor the values changed, so helm-controller had nothing to upgrade, and it did not look at the live objects at all. This is the default.

## Report drift with warn

The field `spec.driftDetection` of a `HelmRelease` changes that. With `mode: warn`, helm-controller compares the live objects of the release with the manifest of the last release on every reconciliation, and reports differences without changing anything. Run `kubectl -n podinfo-production edit helmrelease podinfo` and add this block under `spec`:

```yaml
  driftDetection:
    mode: warn
```

Then reconcile and read the conditions:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get helmrelease podinfo \
  -o jsonpath='{range .status.conditions[*]}{.type}{" "}{.status}{" "}{.reason}{"\n"}{end}'
```

A condition `Drifted` with the status `True` and the reason `DriftDetected` now appears, and the events of the release list the drifted field. The Deployment still has 5 replicas. `warn` is a good first step on a cluster with many manual changes: you see the drift before you start correcting it.

## Correct drift with enabled

With `mode: enabled`, helm-controller corrects the drift too: it applies the release manifest again to the objects that differ. Change the mode with `kubectl -n podinfo-production edit helmrelease podinfo`:

```yaml
  driftDetection:
    mode: enabled
```

Then reconcile:

```sh
flux reconcile helmrelease podinfo -n podinfo-production
kubectl -n podinfo-production get deployment podinfo
```

The Deployment is back at 2 replicas. From now on, a manual change to any field the chart sets lasts at most one `interval` of the release, the same as with a Flux `Kustomization`.

## Exclude a field with an ignore rule

Some fields must be allowed to drift. The classic case is `replicas` on a Deployment that a HorizontalPodAutoscaler scales: drift correction would fight the autoscaler. Another is a value a team tunes by hand while they measure it. `driftDetection.ignore` is a list of rules; each one has `paths`, a list of JSON Pointers, and an optional `target` that selects objects by `kind`, `name`, `namespace` and labels or annotations.

A **JSON Pointer** names one field by its path, with `/` between the parts and list positions as numbers: `/spec/replicas` is the replica count, and `/spec/template/spec/containers/0/resources` is the resources of the first container. A `/` inside a key is written `~1`, and a `~` is written `~0`. A rule that lets an autoscaler own the replicas of the Deployment looks like this:

```yaml
  driftDetection:
    mode: enabled
    ignore:
      - paths: ["/spec/replicas"]
        target:
          kind: Deployment
```

Without `target`, a rule applies to every object of the release that has the path. Keep the rule as narrow as you can: every ignored field is a field Git no longer guarantees.

You can now choose between no drift detection, `warn` and `enabled` for a Helm release, and write an ignore rule for one field. Together with drift correction and pruning in kustomize-controller, you can make both kinds of delivery keep the cluster equal to Git, with exceptions you chose. The graded lab asks you to do exactly that for one release.

## Common pitfalls

> [!WARNING]
> - **Assuming a `HelmRelease` corrects drift like a Flux `Kustomization`.** It does not, until `driftDetection.mode` is `enabled`.
> - **Turning on `enabled` next to an autoscaler.** helm-controller and the autoscaler then fight over `replicas`. Ignore `/spec/replicas` for that Deployment.
> - **A JSON Pointer that names nothing.** A typo in a path ignores nothing and reports nothing. Check the path against the live object with `kubectl get -o json`.
> - **An ignore rule without `target`.** It applies to every object of the release that has the path, which is usually more than you meant.

## Your mission: Make Helm Correct Drift Without Touching Tuned Fields

You can now make helm-controller correct drift, and exclude one field from it. The graded lab gives you a production release whose CPU request the platform team tuned by hand, and asks you to turn on drift correction so that a manual scale is reverted while the tuned request stays.

The lab runs in its own cluster, so first pause your playground. Nothing in it is lost:

```sh
astrona stop ats-096-playground-040-01
```

Then start the lab:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-040/module-01/labs/lab-01
```

The task is on the next page. Solve it on your own first. When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/module-01/labs/lab-01
```

When the lab is done, remove it and start your playground again:

```sh
astrona destroy ats-096-lab-040-01
astrona start ats-096-playground-040-01
```
