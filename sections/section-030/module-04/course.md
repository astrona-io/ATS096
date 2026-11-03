# Install, Upgrade And Uninstall Options

A `HelmRelease` is a request to run Helm for you, and Helm has many settings that decide where a release lives, how long it waits, how much history it keeps, what happens to custom resource definitions and what is left behind when the release is removed. The defaults are sensible, and each one has a case where it is wrong. This module goes through the life of a release in order: install, history, upgrade and uninstall.

Keep one sentence in mind: **helm-controller runs Helm with the settings in the release, and records the result in storage and in the status.** When a release behaves unexpectedly, one of those settings is usually the reason.

The module has four parts. **Names And Namespaces** separates the namespace of the release, the namespace of its objects and the namespace of Helm's storage. **History And Timeouts** limits stored revisions and sets how long each step may take. **Upgrades And Definitions** covers custom resource definitions, failed upgrades and forced runs. **Uninstalling A Release** shows what happens when a release is removed. A graded lab follows the second part.

## Learning objectives

After this module you can:

- Set the release name, the target namespace and the storage namespace separately, and create a missing namespace.
- Limit the history with `maxHistory` and set the timeout of each step.
- Choose a policy for CRDs on install and upgrade.
- Recover a stuck release with `flux reconcile helmrelease --force` and `--reset`.
- Predict what stays behind when a release is deleted.

## Before you start

You need the earlier modules of this section: a `HelmRepository`, a `HelmRelease`, and the remediation settings. The `helm` command is not needed.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system`, including helm-controller |
| Namespaces | `podinfo-staging` and `podinfo-production` exist and are empty |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |
| Internet access | The chart comes from `https://stefanprodan.github.io/podinfo` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
