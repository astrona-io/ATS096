# Helm Drift And Field Ownership

A Helm release is applied by helm-controller, not by kustomize-controller, and the two controllers treat manual changes differently. A Flux `Kustomization` corrects drift (a difference between the live object and Git) on every reconciliation. A `HelmRelease` does not, unless you ask it to. This module covers how helm-controller finds drift, how to report it, how to correct it, and how to leave one field to another writer such as an autoscaler.

Keep one sentence in mind: **helm-controller compares live objects with the manifest of the last release, and `driftDetection.ignore` lists the fields it must not compare.**

The module has four parts. **What helm-controller Compares** reads a drift report. **Writing Ignore Rules** selects fields and objects with JSON Pointers and targets. **Sharing Fields With An Autoscaler** lets another writer own the replicas. **Choosing A Drift Policy** compares the options and their cost. A graded lab follows the third part.

## Learning objectives

After this module you can:

- Report drift with `mode: warn` and read the `Drifted` condition.
- Correct drift with `mode: enabled`.
- Write narrow ignore rules with a path and a target.
- Let another field manager own a field of a Helm release.

## Before you start

You need the basics of a `HelmRelease`: a chart, a version and values, installed by helm-controller. You should be able to read a condition with `kubectl` and run `flux reconcile`.

Your playground is a single-node `kind` cluster with these parts:

| Part | What it is |
| --- | --- |
| Flux v2.9.6 | The `flux` command-line tool on your machine, and the Flux controllers in the namespace `flux-system` |
| `HelmRelease` `podinfo` | In `podinfo-production`: chart podinfo `6.15.0` with 2 replicas and no drift detection |
| Flux `Kustomization` `podinfo-staging` | Applies `./apps/podinfo/base` into `podinfo-staging` |
| `tester` (namespace `gitea`) | A client pod with `curl` and `jq` |

Launch your playground now, and keep it running next to you while you read the parts:

<!-- astrona:playground -->
