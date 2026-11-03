# Versions And Reconcile Strategy

A chart version in a `HelmRelease` can be exact or a range. A range makes upgrades happen without a commit, which is useful for patch releases and dangerous for everything else. This part shows the version forms, what each one selects, and the second setting that decides whether a changed chart counts as new: the reconcile strategy.

## Version forms

The field `spec.chart.spec.version` takes a semantic version constraint. A semantic version has three numbers, `major.minor.patch`, where a higher major number may break compatibility. source-controller compares the versions in the index with the constraint and selects the highest one that fits.

| Value | Selects |
| --- | --- |
| `6.15.0` | Exactly this version |
| `6.x` or `^6.0.0` | The highest 6.y.z version |
| `~6.15.0` | The highest 6.15.z version |
| `>=6.0.0 <7.0.0` | The highest version in the range |
| `*` | The highest stable version |
| Not set | The highest stable version, the same as `*` |

A version with a suffix, for example `6.16.0-rc.1`, is a pre-release. A range does not select pre-releases unless the constraint includes one, for example `>=6.0.0-0`.

## See a range select

Change the release to a range and look at the chart:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"chart":{"spec":{"version":"6.x"}}}}'
flux reconcile helmrelease podinfo -n podinfo-staging
flux get sources chart -n podinfo-staging
flux get helmreleases -n podinfo-staging
```

The `HelmChart` revision is now the highest 6.y.z version that the repository holds, which may be higher than `6.15.0`. If it is higher, the release upgrades to it. This is the risk of a range: the cluster changes while Git does not. Set the exact version back before you continue:

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"chart":{"spec":{"version":"6.15.0"}}}}'
flux reconcile helmrelease podinfo -n podinfo-staging
```

A range in a development stage and an exact version in production is a common split. Then a new chart reaches staging first.

## Reconcile strategy

`spec.chart.spec.reconcileStrategy` decides when the `HelmChart` produces a new artifact. With `ChartVersion`, the default, a new artifact is made only when the version in `Chart.yaml` changes. With `Revision`, a new artifact is made when the revision of the source changes, which for a `GitRepository` is every new commit.

For a chart in a chart repository, the version number is the only change you can see, so `ChartVersion` is right. For a chart that lives in Git, `Revision` is the safe choice during development, because developers change templates without bumping `version` in `Chart.yaml`. With `ChartVersion`, those edits would never reach the cluster.

```sh
kubectl -n podinfo-staging get helmchart podinfo-staging-podinfo -o jsonpath='{.spec.reconcileStrategy}{"\n"}'
```

The output is `ChartVersion`. The next part uses `Revision` on a chart from Git.

You can now pin a version, use a range on purpose, and choose when a changed chart counts as new. The chart so far came from a chart repository. The next part installs one from Git.

## Common pitfalls

> [!WARNING]
> - **A range in production.** The cluster upgrades without a commit, and the change is not in Git.
> - **`ChartVersion` for a chart under development in Git.** Template edits without a version bump never arrive.
> - **Expecting a range to select a pre-release.** Stable constraints skip them.
> - **Reading the version of the `HelmRelease` as the installed version.** Read the revision of the `HelmChart`, or `status.history`.
