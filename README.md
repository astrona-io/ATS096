# ATS096 — Kustomize & Helm Controller Reconciliation (FluxCD)

Course material for the **Kustomize & Helm Controller Reconciliation** domain
of the Astrona FluxCD training path ([ATP019](https://github.com/astrona-io/ATP019)),
which is **25% of the path**. Written for **Flux v2.9.6** and the podinfo
Helm chart **6.15.0**.

> **Status: draft, not yet run.** Every page, playground and lab was written
> from the Flux v2.9 documentation. None has been started on a cluster, and
> no lab has passed `astrona test` yet. See `CLAUDE.md`.

The course opens with an Introduction in `sections/intro/` (welcome, machine setup,
how the course is made). Everything else lives under `sections/`. Each section
contains:

- **Modules** — a reading chapter split into a short landing page, ordered
  deep-dive parts and a summary page, a throwaway **playground** to explore in,
  and a graded **lab** placed right after the part it tests.
- **A capstone** — one larger graded lab combining that section's modules into a
  single scenario with several independent faults.

---

## Sections

| Section | Title | Modules | Labs | Topic |
| --- | --- | --- | --- | --- |
| [010](sections/section-010) | The Flux Kustomization In Depth | 1 | 1 + capstone | Building and shaping what Flux applies |
| [020](sections/section-020) | Dependencies And Health Checks | 1 | 1 + capstone | Ordering and gating |
| [030](sections/section-030) | Deploying Helm Charts With HelmRelease | 1 | 1 + capstone | Helm delivery and remediation |
| [040](sections/section-040) | Drift Detection, Correction And Pruning | 1 | 1 + capstone | Keeping the cluster equal to Git |

The order follows one delivery from build to day two. Section 010 shapes what
kustomize-controller builds; section 020 orders and gates those builds into a
pipeline; section 030 does the same for Helm charts; section 040 keeps the
result equal to Git after people start changing things by hand.

---

## Modules

| Module | Reader | Parts | Labs |
| --- | --- | --- | --- |
| 010-01 | [Shape What Flux Applies With The Flux Kustomization](sections/section-010/module-01/course.md) | 3 | [lab-01](sections/section-010/module-01/labs/lab-01) |
| 020-01 | [Order And Gate Deployments With dependsOn And Health Checks](sections/section-020/module-01/course.md) | 3 | [lab-01](sections/section-020/module-01/labs/lab-01) |
| 030-01 | [Deploy Helm Charts With HelmRelease](sections/section-030/module-01/course.md) | 3 | [lab-01](sections/section-030/module-01/labs/lab-01) |
| 040-01 | [Keep The Cluster Equal To Git](sections/section-040/module-01/course.md) | 3 | [lab-01](sections/section-040/module-01/labs/lab-01) |

---

## Capstones

| Capstone | Scenario | Faults |
| --- | --- | --- |
| [010](sections/section-010/capstone/labs/lab-01) | Repair The Overlays Of Two Environments | a target namespace that does not exist, a missing variable source, a patch that matches nothing |
| [020](sections/section-020/capstone/labs/lab-01) | Unblock A Stuck Delivery Pipeline | a wrong path, a health check on a missing Deployment, a dependency name typo |
| [030](sections/section-030/capstone/labs/lab-01) | Repair Two Helm Releases | an OCI tag that does not exist, a `sourceRef` without its namespace, a wrong `valuesKey` |
| [040](sections/section-040/capstone/labs/lab-01) | Keep Two Environments Equal To Git | pruning off with a leftover object, an `ssa: IfNotPresent` annotation in Git, Helm drift detection in `warn` |

---

## The lab environment

Every playground and lab is a **kind** cluster with an in-cluster Git server
(Gitea, `gitea/gitea:28.2.0-rootless`) holding the repository `gitops/fleet`,
the Flux CLI 2.9.6 on the machine, the Flux controllers, the `GitRepository`
`fleet` already `Ready`, and the namespaces `podinfo-staging` and
`podinfo-production`. Sections 030 and 040 also need outbound internet for the
podinfo chart.

The repository address is `http://gitea.localtest.me:3000/gitops/fleet.git`
everywhere: on the reader's machine through
`kubectl -n gitea port-forward svc/gitea-http 3000:3000`, and inside the
cluster through a CoreDNS rewrite added by the bootstrap. Credentials are the
lab-only `gitops` / `gitops-password`.

The shared plumbing of the twelve environments (`lab-start.yaml`,
`01-install-git-and-flux.sh` or `prepare.sh`, `wait-for-flux.sh`,
`source.yaml`, `namespaces.yaml`, `config.yaml`, author READMEs,
`prerequisites.md`) is identical apart from names. Change it everywhere at
once.

## Running a playground

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/<section>/<module>/playground
astrona destroy <name>
```

## Running a lab

Labs and capstones are graded. Read `question.md`, do the work, and submit:

```bash
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/<section>/<module>/labs/lab-01
astrona submit -c sections/<section>/<module>/labs/lab-01
astrona destroy <name>
```

Each lab grades the **final cluster and Git state** with independent checks,
and several of them deliberately reject the plausible-but-wrong fix (applying
the application with `kubectl`, removing `dependsOn` or a health check,
`optional: true` on a missing values source, drift detection left at `warn`,
fixing a live object instead of Git).
