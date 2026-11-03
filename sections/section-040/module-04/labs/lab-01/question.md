# Question

Solve this question on: `terminal`

**Time:** about 20 minutes · **Topic:** Helm drift and field ownership

## Scenario

podinfo runs in `podinfo-production` from the `HelmRelease` `podinfo`, with 2 replicas from its values. Drift detection is already `enabled`, so helm-controller corrects every manual change on each reconciliation. The team now adds a horizontal autoscaler that writes `spec.replicas` of the Deployment. Each time the release reconciles, helm-controller sets the replicas back to 2.

## Your task

Change the `HelmRelease` `podinfo` in `podinfo-production` so that helm-controller no longer touches the replica count of the Deployment, and still corrects drift in every other field.

## Constraints

- Do not switch drift detection off or to `warn`.
- Do not change the chart, the chart version or the values.
- Ignore only `/spec/replicas`, and only on Deployments.
- Do not delete and recreate the `HelmRelease`.

## Done when

- `driftDetection.mode` is `enabled` and the only ignore rule has the path `/spec/replicas` and the target kind `Deployment`.
- After another writer sets 4 replicas and the release reconciles, the Deployment still has 4 replicas.
- After a hand-made change to the CPU request and a reconciliation, the request is back at the chart value.
