# Section 040: Drift Detection, Correction And Pruning

GitOps promises that the cluster equals Git. Two things break that promise every day. Someone changes a live object by hand, and the cluster drifts away from Git. Or a file disappears from Git, and the object it created stays behind in the cluster. Flux handles both, but kustomize-controller and helm-controller handle them differently, and both can be told to leave some things alone.

This section shows how each controller finds and corrects drift, how pruning decides what to delete, and how to make exceptions on purpose without losing the guarantee.

**Topic covered:** keeping the cluster equal to Git

## What you will learn

- How kustomize-controller finds and corrects drift with server-side apply, and what field managers have to do with it.
- The annotations `kustomize.toolkit.fluxcd.io/ssa`, `prune` and `reconcile`, and when each one is the right exception.
- Pruning with the inventory, and the deletion policies of a Flux `Kustomization`.
- Drift detection in helm-controller: off, `warn` and `enabled`, and ignore rules with JSON Pointers.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground.

### 1. Keep The Cluster Equal To Git

The playground runs podinfo twice: staging from the Git base with a Flux `Kustomization`, and production from the Helm chart with a `HelmRelease`. It needs outbound internet for the chart.

1. Drift Correction With Server-Side Apply
2. Pruning, The Inventory And Deletion Policies
3. Drift Detection In helm-controller, followed by the lab **Make Helm Correct Drift Without Touching Tuned Fields**
4. Summary

## Section capstone: Keep Two Environments Equal To Git

The capstone is one graded scenario that uses everything in the module. Staging has an object that Git deleted weeks ago and a change that never arrives, and production only warns when someone scales it by hand. Two of the faults are in Git, so you fix them with a commit. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-040/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-040/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-096-capstone-040
```
