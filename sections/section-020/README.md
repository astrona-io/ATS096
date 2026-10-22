# Section 020: Dependencies And Health Checks

Flux reconciles every Flux `Kustomization` on its own. Without more information it applies them all at once, in no particular order, and reports each one `Ready` as soon as its objects are stored in the cluster. Real delivery needs more than that: the cache must run before the application that uses it, and a change must prove itself in staging before it may touch production.

This section adds order and proof. `dependsOn` makes one Flux `Kustomization` wait for another, and health checks make `Ready` mean that the applied workloads really run. Together they turn separate Flux objects into a pipeline that stops a bad commit in staging.

**Topic covered:** ordering and gating

## What you will learn

- Making a Flux `Kustomization` wait for others with `dependsOn`, and reading the reason `DependencyNotReady`.
- Why `dependsOn` only means something when the dependency checks health.
- The difference between `wait: true`, `healthChecks` and `healthCheckExprs`, and when each one fits.
- How `timeout` and `retryInterval` decide how long a failing health check takes and how often it runs again.
- Building a staged pipeline in which production waits for a healthy staging, and watching it stop a bad commit.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Order And Gate Deployments With dependsOn And Health Checks

The playground holds Flux, the repository `gitops/fleet` with a `redis` cache in `infrastructure/redis` and the `podinfo` base in `apps/podinfo/base`, and empty namespaces for staging and production.

1. Ordering With dependsOn
2. Health Checks, Timeouts And Retries
3. A Staged Pipeline From Staging To Production, followed by the lab **Build A Staged Pipeline From Staging To Production**
4. Summary

## Section capstone: Unblock A Stuck Delivery Pipeline

The capstone is one graded scenario that uses everything in the module. A three-stage pipeline has not delivered anything for a day. Each stage is stuck for a different reason, and the obvious way to unblock it, removing the dependencies and the health checks, is exactly what the pipeline must keep. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-020/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-020/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-096-capstone-020
```
