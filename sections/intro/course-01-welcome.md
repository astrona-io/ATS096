# Welcome To The Course

This course trains you for the **Kustomize & Helm Controller Reconciliation** part of the Astrona **FluxCD** training path. That part is 25% of the path, the largest one. This page tells you who the course is for, what you can do at the end, which words and example setup it uses, and how its pages fit together.

## Who this course is for

You know your way around Kubernetes: namespaces, Deployments, Services, ConfigMaps, Secrets, labels, `kubectl apply`, `kubectl get` and `kubectl edit`. You can use Git from the terminal: clone, commit, push and revert. You know what Flux does in broad terms: a `GitRepository` makes Flux fetch a repository, and a Flux `Kustomization` makes it apply a folder of it. You do not need to know Kustomize or Helm in depth. Each new idea is explained the first time it appears.

## What you can do at the end

This course is about delivering applications with Flux and keeping them the way Git says. It asks you to build deliveries, break them, and prove that they work. The course has four topics, and each one turns into a set of skills you will practise.

The first topic is **the Flux `Kustomization` in depth**. You will learn to:

- Explain what kustomize-controller does with a folder, and preview it with `flux build` and `flux diff`.
- Deploy one base into two environments with `targetNamespace`, patches and variable substitution.

The second topic is **dependencies and health checks**. You will learn to:

- Order deliveries with `dependsOn`, and make `Ready` mean "running" with health checks.
- Build a pipeline from staging to production that stops a bad commit in staging.

The third topic is **Helm charts with `HelmRelease`**. You will learn to:

- Install a chart from a chart repository and from an OCI registry, with values from ConfigMaps and Secrets.
- Make helm-controller roll back a failed upgrade, and read what happened in Helm's own records.

The fourth topic is **drift detection, correction and pruning**. You will learn to:

- Predict what Flux does to a manual change, and make exceptions with annotations.
- Follow objects through the inventory and pruning, and turn on drift correction for a Helm release.

Everything is written for **Flux v2.9.6** and the podinfo Helm chart **6.15.0**.

## The words this course uses

The pages use Flux's, Kustomize's, Helm's and Kubernetes' own terms, because those are the words you meet in the product, the logs and the documentation. Each term gets a short, plain definition the first time it appears on a page. A few terms come back on almost every page, so here they are up front.

A **controller** is a program in the cluster that watches some kinds of objects and keeps changing the cluster until it matches them. One such run is a **reconciliation**. **Drift** is any difference between the cluster and Git. **Kustomize** is the tool that builds a folder of YAML files into final manifests, and **Helm** is the tool that installs a chart, a package of templates plus default values, as a numbered **release**.

Four Flux objects come back on almost every page:

| Object | Controller | What it does |
| --- | --- | --- |
| `GitRepository` | source-controller | Fetches a Git repository |
| Flux `Kustomization` | kustomize-controller | Builds one folder of a source and applies it |
| `HelmRepository` | source-controller | Fetches the index of a Helm chart repository |
| `HelmRelease` | helm-controller | Installs and upgrades one Helm release |

The Flux `Kustomization` object is not the same thing as the Kustomize file `kustomization.yaml`, even though the names are alike. The pages always say which one they mean.

## The example setup in your playground

Every playground and lab runs the same small setup. Flux runs in the namespace `flux-system`, already connected to a Git repository, `gitops/fleet`, on a Git server called Gitea inside the cluster. The repository holds one base for the demo application `podinfo`, a small web server that answers with a short JSON message. You deploy it twice: into `podinfo-staging` and into `podinfo-production`. Some modules use podinfo's Helm chart instead, and one adds a `redis` cache. A `tester` pod sends requests to podinfo, so you can see which message each environment answers with.

Many labs start with something broken on purpose. That is the material, not a fault in the course.

## How the course is laid out

The course has four sections. It starts with how Flux builds what it applies, then orders and gates the deliveries, then moves to Helm charts, and ends with keeping everything equal to Git.

| Section | What it covers |
| --- | --- |
| 010 | The Flux Kustomization In Depth |
| 020 | Dependencies And Health Checks |
| 030 | Deploying Helm Charts With HelmRelease |
| 040 | Drift Detection, Correction And Pruning |

Each section has one or more **modules**, and each module teaches one skill. A module brings together four kinds of material:

| What | What it is for | Graded? |
| --- | --- | --- |
| **Reading** | A short landing page, a few chapters that teach one idea each, and a summary | No |
| **Playground** | A small cluster on your own machine, to try everything you read | No |
| **Lab** | A cluster in a starting state, a task, and a grader that checks your work | Yes |
| **Capstone** | The last lab in a section, with several faults at once | Yes |

The best order is simple: read the chapters with the playground open next to them, take each lab when a chapter sends you to it, and finish each section with its capstone. The next part of this page explains how a module's pages guide you through that order.

## How to read a page

A module starts with a **landing page**. It says what the module teaches, what you should know first, and the order of its chapters. At the bottom of the landing page you start the module's playground, and you keep it running while you read.

The chapters (the parts of a module) read like the chapters of a technical book. Each one opens with the problem it solves, explains one idea in connected paragraphs, and closes with what you now know. The hands-on steps sit right in the text: a sentence or two on what to run and why, the command, and then what the result shows. Run each step in your playground as you reach it. You learn more from one real result than from a page of text.

Every chapter ends with a box of common pitfalls, the mistakes people make most often with what the chapter taught, and how to spot them. Now and then a page also has a tip box with a habit or shortcut you can use again, well beyond that page. The two boxes look like this:

> [!TIP]
> **A tip.** A habit or shortcut you can use again, well beyond this one page.

> [!WARNING]
> **Common pitfalls.** The mistakes people make most often with what you just learned, and how to spot them. Every chapter ends with one.

When a graded lab tests what a chapter taught, that chapter ends with a **Your mission** section. It tells you what the lab asks, then gives every command you need, in order: pause the playground with `astrona stop`, start the lab with `astrona run`, and send your work for grading with `astrona submit`. Solve the lab on your own before you look at its solution. When the lab is done, remove it with `astrona destroy` and start the playground again with `astrona start`, so you can carry on reading where you left off.

The last page of every module is the **Summary**. It sums up what you learned in a few short paragraphs, organised by idea. It also ends the module's hands-on work: the Summary page removes the playground, so your machine is clean before the next module.

One rule holds on every page. Code blocks are exactly what you type. Never change a command to make it "look right". If the result is different from what the page describes, that difference is the lesson.
