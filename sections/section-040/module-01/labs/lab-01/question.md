# Question

Solve this question on: `terminal`

**Time:** about 25 minutes · **Topic:** keeping the cluster equal to Git

## Scenario

podinfo runs in `podinfo-production` from the `HelmRelease` `podinfo`, with 2 replicas from its values. Last night someone scaled it to 6 replicas by hand to "help" during a load test and forgot it; helm-controller never put it back. At the same time, the platform team is measuring CPU and has set the CPU request of the `podinfo` container to `50m` by hand. That value must stay until they finish.

## Your task

Change the `HelmRelease` `podinfo` in `podinfo-production` so that:

1. helm-controller **corrects** drift on every reconciliation, not only reports it.
2. The resources of the `podinfo` container in the Deployment are **excluded** from drift correction, so the hand-tuned CPU request of `50m` stays.

Exclude only what is needed: the container resources of the Deployment, not other fields and not other objects.

## Constraints

- Do not change the chart, the chart version or the values.
- Do not set the CPU request in the values; the team is still measuring it.
- Do not delete and recreate the `HelmRelease`.

## Done when

- After `kubectl -n podinfo-production scale deployment podinfo --replicas=5` and `flux reconcile helmrelease podinfo -n podinfo-production`, the Deployment is back at 2 replicas.
- After the same reconciliation, the CPU request of the `podinfo` container is still `50m`.
