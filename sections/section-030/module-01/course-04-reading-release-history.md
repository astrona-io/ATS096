# Reading Release History And Status

When a release misbehaves, the answer is almost always already stored: in the conditions of the `HelmRelease`, in its history, and in the Secrets that Helm keeps for each revision. This part shows where each record lives and what it tells you, so that you can reconstruct what helm-controller did without guessing.

## Conditions of the HelmRelease

The field `status.conditions` of a `HelmRelease` holds the result of the last reconciliation. The condition `Ready` is `True` when the release is installed or upgraded and healthy. The condition `Released` says whether the last Helm action succeeded, and its reason names the action, for example `InstallSucceeded`, `UpgradeSucceeded` or `UpgradeFailed`. The condition `Remediated` appears after a rollback or an uninstall that remediation ran.

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-staging get helmrelease podinfo -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

The output has one line for each condition. Read the reason first: it tells you which Helm action ran and how it ended.

## The history in the status

The field `status.history` is a list with one entry for each recent release revision. Each entry has the chart name and version, the app version, the Helm revision number as `version`, the `status` of the revision (`deployed`, `superseded` or `failed`), and the digest of the values that were used. The newest entry comes first.

```sh
kubectl -n podinfo-staging get helmrelease podinfo -o jsonpath='{range .status.history[*]}{.version} {.status} {.chartName} {.chartVersion}{"\n"}{end}'
```

An upgrade that failed shows an entry with the status `failed`, and, after a rollback, the older revision comes back as a new revision with the status `deployed`. This is the quickest way to answer the question "what is deployed now, and what was before".

## The Helm storage Secrets

Helm itself stores each revision of a release as a Secret in the namespace of the release, named `sh.helm.release.v1.<release>.v<revision>`. helm-controller uses these Secrets as the source of truth when it decides between an install and an upgrade. The labels `owner=helm`, `name` and `status` make them easy to list:

```sh
kubectl -n podinfo-staging get secrets -l owner=helm,name=podinfo -L version,status
```

One row appears for each stored revision. The number of revisions kept follows `maxHistory` on the `HelmRelease`, which is 5 unless you change it. When the status shows more history than you expect, compare it with these Secrets: they are what Helm sees.

## Events and the last attempt

The records above show the result. The events show the sequence. `flux events --for HelmRelease/podinfo --namespace podinfo-staging` lists what helm-controller did, including each retry and each rollback. The fields `status.lastAttemptedRevision`, `status.lastAppliedRevision` and `status.failures` tell you which chart revision was tried, which one is deployed, and how many attempts failed.

```sh
flux events --for HelmRelease/podinfo --namespace podinfo-staging
kubectl -n podinfo-staging get helmrelease podinfo -o jsonpath='{.status.failures} {.status.lastAttemptedRevision} {.status.lastAppliedRevision}{"\n"}'
```

You can now read a release from four sides: conditions, history, storage Secrets and events. With these four records you can explain any state a release is in, including the states that remediation and rollback leave behind.

## Common pitfalls

> [!WARNING]
> - **Reading only `flux get helmreleases`.** The table message is cut short. The conditions and events hold the full text.
> - **Counting Secrets and expecting an exact match with `maxHistory`.** Helm removes old revisions when it runs, so the number can briefly be higher.
> - **Confusing the chart version with the Helm revision.** The chart version is `6.15.0`; the revision is the number of the install or upgrade.
