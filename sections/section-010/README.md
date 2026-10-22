# Section 010: The Flux Kustomization In Depth

A Flux `Kustomization` is the object that tells kustomize-controller which folder of a Git repository to build and apply. A simple one points at a folder and applies it as it is. A real cluster needs more: the same application in two namespaces, a different replica count in production, and a message or a label that differs per environment. All of that lives in the Flux `Kustomization`, not in copies of the YAML.

This section opens up the build that kustomize-controller runs on every reconciliation. You compare it with the Kustomize command-line tool, preview it with `flux build` and `flux diff`, and change it with three tools: `targetNamespace`, patches and post-build variable substitution.

**Topic covered:** building and shaping what Flux applies

## What you will learn

- What kustomize-controller does with a folder, step by step, and how that differs from `kubectl kustomize`.
- Previewing a build with `flux build kustomization` and comparing it with the cluster with `flux diff kustomization`.
- Deploying one base folder into two namespaces with `targetNamespace`.
- Changing built objects with strategic merge patches and JSON6902 patches, and choosing their target.
- Replacing `${variables}` after the build with `postBuild.substitute` and `postBuild.substituteFrom`, with defaults and with `optional`.

## The learning path

The module has a landing page, three short parts, a graded lab right after the part it tests, and a summary. The landing page starts the module's playground, a cluster where you can explore freely.

### 1. Shape What Flux Applies With The Flux Kustomization

The playground holds Flux, an in-cluster Git server with the repository `gitops/fleet`, and a base folder for the `podinfo` application. No Flux `Kustomization` exists yet; you create them.

1. The Flux Kustomization And Kustomize
2. Target Namespaces And Patches
3. Variable Substitution After The Build, followed by the lab **Deploy One Base To Two Environments**
4. Summary

## Section capstone: Repair The Overlays Of Two Environments

The capstone is one graded scenario that uses everything in the module. Two Flux `Kustomization` objects deploy the same base to staging and production, and both are wrong in different ways: one fault stops a build, one stops an apply, and one changes nothing at all without any error. Work it after the module lab.

Start the capstone:

```sh
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-010/capstone/labs/lab-01
```

When you think you are done, send it for grading:

```sh
astrona submit -c sections/section-010/capstone/labs/lab-01
```

When the capstone is done, remove it:

```sh
astrona destroy ats-096-capstone-010
```
