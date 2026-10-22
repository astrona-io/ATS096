# Question

Solve this question on: `terminal`

**Time:** about 35 minutes · **Topic:** Helm delivery and remediation

## Scenario

podinfo is installed with Helm in two ways. Staging tries out the OCI registry: it uses the `OCIRepository` `podinfo-chart` in its own namespace. Production uses the chart repository through the `HelmRepository` `podinfo` in `flux-system`, and keeps its values in the Secret `podinfo-values`. Neither release has ever installed. The platform team owns the Secret and says its content is correct.

## Your task

Make both `HelmRelease` objects named `podinfo` install chart podinfo **`6.15.0`**:

1. **Staging** installs from the `OCIRepository` `podinfo-chart` through `chartRef`, and answers with the message **`staging`**.
2. **Production** installs from the `HelmRepository` `podinfo`, takes its values from the Secret **`podinfo-values`**, answers with the message **`production from Secret`**, and runs **2** replicas.

## Constraints

- Do not change the Secret `podinfo-values`, and do not create another one.
- Do not mark a values source as `optional`, and do not move production's values inline.
- Keep staging on the OCI registry, through `chartRef`.
- Do not delete and recreate the `HelmRelease` objects.

## Done when

- `flux get helmreleases -A` shows both releases `Ready`.
- podinfo answers `staging` in `podinfo-staging`, and `production from Secret` with 2 replicas in `podinfo-production`.
