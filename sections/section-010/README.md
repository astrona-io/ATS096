# Section 010: The Flux Kustomization In Depth

A Flux `Kustomization` is the object that tells kustomize-controller which folder of a Git repository to build and apply. A simple one points at a folder and applies it as it is. A real cluster needs more: the same application in two namespaces, a different replica count in production, and a message or a label that differs per environment. All of that lives in the Flux `Kustomization`, not in copies of the YAML.

This section opens up the build that kustomize-controller runs on every reconciliation. You compare it with the Kustomize command-line tool, preview it with `flux build` and `flux diff`, and change it with `targetNamespace`, patches, images, Kustomize files, replacements and post-build variable substitution, and you secure and pause it.

**Topic covered:** building and shaping what Flux applies

## What you will learn

- What kustomize-controller does with a folder, step by step, and how that differs from `kubectl kustomize`.
- Previewing a build with `flux build kustomization` and comparing it with the cluster with `flux diff kustomization`.
- Deploying one base folder into two namespaces with `targetNamespace`.
- Changing built objects with strategic merge patches and JSON6902 patches, choosing their target, and changing images, names and metadata with `images`, `namePrefix` and `commonMetadata`.
- Replacing `${variables}` after the build with `postBuild.substitute` and `postBuild.substituteFrom`, with defaults and with `optional`.
- Building environments with Kustomize files: bases, overlays, transformers, generators with hash suffixes, and components.
- Moving values inside a build with replacements, and debugging a failed build with `flux build`, `flux diff`, events and `flux trace`.
- Decrypting Secrets with SOPS and age, limiting an apply with `serviceAccountName`, choosing a source kind, and pausing with `flux suspend`.

## The learning path

The section has four modules. Each module has a landing page that starts its own playground, reading parts, a graded lab right after the part it tests, and a summary. The three newer modules end with a knowledge check.

### 1. Shape What Flux Applies With The Flux Kustomization

The playground holds Flux, an in-cluster Git server with the repository `gitops/fleet`, and a base folder for the `podinfo` application. No Flux `Kustomization` exists yet; you create them.

1. The Flux Kustomization And Kustomize
2. Target Namespaces And Patches
3. Variable Substitution After The Build, followed by the lab **Deploy One Base To Two Environments**
4. Patch Targets And Image Overrides
5. Summary

### 2. Build Environments With Kustomize Files

The playground repository holds a base, a staging and a production overlay, and a Kustomize component.

1. Bases And Overlays
2. Images, Replicas And Labels
3. Generators And Hash Suffixes, followed by the lab **Roll Pods With A Generated ConfigMap**
4. Components
5. Summary, then a knowledge check

### 3. Replacements And Debugging Builds

The playground repository holds a base and an overlay that uses a replacement.

1. Replacements
2. Preview Builds Locally
3. Read Kustomize Controller Errors, followed by the lab **Repair A Build That Uses Replacements**
4. Trace And Debug Workflow
5. Summary, then a knowledge check

### 4. Securing And Sourcing Kustomizations

The playground has age and sops installed next to Flux, and a base whose Deployment reads a Secret that is not in the repository yet.

1. Decrypt Secrets With SOPS And Age, followed by the lab **Decrypt A Secret With SOPS And Age**
2. Impersonate A Service Account
3. Source Kinds And Cross-Namespace References
4. Suspend, Resume And Reconcile Controls
5. Summary, then a knowledge check

## Section capstone: Repair The Overlays Of Two Environments

The capstone is one graded scenario that uses the first module. Two Flux `Kustomization` objects deploy the same base to staging and production, and both are wrong in different ways: one fault stops a build, one stops an apply, and one changes nothing at all without any error. Work it after the lab of the first module.

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
