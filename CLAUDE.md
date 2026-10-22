# Writing style for this repo

All study text here (course pages, lab docs, READMEs, comments in YAML and
scripts) is for people learning a technical subject, often for a
certification exam. Many of them are not native English speakers and have no
university degree.

## Technical documentation in plain English

This is technical documentation. Say exactly what the system does, with the
real technical terms, in clear and simple English. Never hide a concept
behind a metaphor, a made-up name or a vague word: the reader must learn the
words they will meet in the product, the logs and the exam.

Strict guidelines:

1. Use the correct technical term every time (request, response, pod,
   namespace, Service, sidecar proxy, certificate, mTLS, JWT, listener). The
   first time a term appears in a file, define it in one plain sentence that
   says what it is and what it does. Spell out every acronym on first use.
2. No metaphors or analogies in explanations. Not "the communications
   officer", but "the sidecar proxy (Envoy)"; not "a signal", but "a
   request"; not "the planet", but "the namespace".
3. Simple sentences. Target a Flesch-Kincaid Grade Level of 8 or 9 for the
   prose around the terms. Keep sentences direct; split long sentences into
   two. No corporate buzzwords.
4. Use short paragraphs (max 3-4 sentences per paragraph).
5. Use the active voice ("istiod sends the configuration", not "the
   configuration is sent").

## How this applies to course material

- **Know which file you are in.** A module has a short landing page, a few
  deep-dive parts and a summary page. The landing page is a map: goals, what
  to know first, the order of the parts. The real teaching goes in the parts.
  The summary closes the module. A lab
  has a task, a step-by-step solution and a short intro. Keep each file to its
  job. Do not add "Prerequisite: ... Next: ..." navigation lines to pages;
  the landing page and the course outline already give the order.
- **Keep each part short.** One idea per part, about 5 to 8 minutes of
  reading and at most about 8 command blocks, so a learner can finish it with
  the playground in one sitting of about 15 minutes. Split at a natural seam
  where each half ends with something the learner has seen work. Never split
  only to hit a number. When you split, renumber the files, fix every "Part N"
  reference in the module and `astrona.yaml`.
- **Read like a book, not like a web page.** Each part reads as a chapter of
  a technical book. Open with a short paragraph on the problem it solves and
  why it matters. Link each paragraph to the next with a transition sentence.
  Close with a paragraph that sums up what the reader now knows and the
  question still open, before `## Common pitfalls` and the mission. Write
  explanations as prose; keep bullets for real lists (fields, ordered steps,
  options). Use `##` only when the topic changes and `###` only inside a long
  section, never for a single command. Weave hands-on steps into the text:
  one or two sentences on what to run and why, the command, the real output,
  then a sentence or two on what it shows.
- **The module ends with a summary.** The last page of every module is
  `course-0N-summary.md` with the title `# Summary`: a few short prose
  paragraphs on what the reader learned, organised by idea, optionally with
  one short list of key facts. It names no parts, modules, sections or
  chapters, and has no links, lab table, quiz or commands. Its last line is
  `<!-- astrona:playground:destroy -->` on its own line; the platform turns it
  into the step that removes the playground.
- **Every heading gets an intro.** A `##` section that has `###`
  subsections starts with one to three sentences that say what the section
  is about and why it matters, before the first `###`. Never put a `###`
  directly under a `##`.
- **Every module stands on its own.** Never refer to other sections or
  modules: no "see section 040", "as module 3 showed", "you met this in
  section 000", and no links to pages in another module. If the reader needs
  a fact from elsewhere, state the fact directly in one or two sentences.
  This also goes for parts of the same module: never write "Part 2 shows",
  "from Part 1" or "as in Part 3". Say the fact itself ("the commands below
  need the `scout` `DestinationRule` applied"). This includes the summary.
  The landing page does not have a "Where this fits" section.
- **Write words out in full.** Do not use informal short forms in prose:
  write "communications", "configuration", "repository", "administrator",
  "for example" and "that is", never "comms", "config", "repo", "admin",
  "e.g." or "i.e.". Names in code, commands and file paths stay as they are.
- **Exam terms stay.** The product's own names are what the reader must learn
  (for example a resource kind, a field, a command). Use them as they are and
  define each one in plain technical words the first time it appears in a
  file. Spell out acronyms on first use, with a short plain meaning.
- **The space theme is only for examples.** Space appears in two places and
  nowhere else: the names of the example workloads (the Starfleet: `bridge`,
  `scout`, `shuttle`, `probe`, the `starfleet` and `outpost` namespaces) and
  the short scenario that opens a lab task or a practice exercise (for
  example "the `drifter` in `outpost` must keep reaching the probe"). The
  explanation around an example is plain technical text: write "the
  `shuttle` pod sends a request to the `probe` Service", never "the shuttle
  sends a signal to the probe ship". Do not address the reader as an
  astronaut, and do not use space metaphors (communications officer, mission
  control, badge, airlock, guest list, star chart) for Istio or Kubernetes
  concepts. Titles of pages and labs name the technical task ("Require mTLS
  With PeerAuthentication"), not a space story.
- **Show one real example before the rule.** Start with a concrete case the
  reader can run, then give the general rule.
- **Say which part does the work.** Readers often mix up the parts of a system
  that sit close together. Whenever something happens, say which component
  did it.
- **Never change code to fit the style.** Commands, configuration files, field
  names, resource names, log lines and command output stay exactly as they
  are. They were run and checked on a real system. Never make up command
  output. If you shorten it, say that you did.
- **Prose only.** The grade-level and sentence rules apply to explanations.
  They do not apply to code blocks, tables of field names or reference lists
  (those may stay short and dense).
- **Keep the page furniture the same.** Hands-on steps are part of the prose
  (see "Read like a book"), not boxes or headings of their own. A `> [!TIP]` box is
  only for a real tip: advice the reader can reuse beyond this one step (a
  habit, a shortcut, how to spot a problem, an exam habit). Everything else
  is a normal sentence: notes about the current step ("if the log line is
  old, run it again"), background facts, optional extra steps, and plain
  information. Never a command snippet, never two in a row, and most pages
  need zero or one tip. Each part ends with a
  `## Common pitfalls` `> [!WARNING]` block for that part only. Use a Mermaid
  diagram for a flow, an order or a state change, keep it under about 12
  boxes, and follow it with one sentence that says what it shows.
- **Labs come right after the part they practise.** Do not collect all
  graded labs at the end of a module. In `astrona.yaml`, put each lab (its
  `question.md` reading and the `lab` entry) right after the reading part it
  tests. If a part teaches a gradeable skill and no lab covers it, create a
  new lab. That part then ends with a `## Your mission: <lab title>` section:
  one sentence on what the reader can now do, one on what the mission asks,
  then pause the playground (`astrona stop <playground name>`), the
  `astrona run` and `astrona submit` commands, and finally
  `astrona destroy <lab name>` plus `astrona start <playground name>`.
- **Renew the playground before hands-on work.** Every reading part that
  runs commands has `<!-- astrona:playground:renew -->` exactly once, on its
  own line, right before the first hands-on step (the first "Save this as"
  or the first command block), so the playground timer is reset before the
  learner needs the playground. Not on landing pages (they carry
  `<!-- astrona:playground -->`), summary pages (they carry
  `<!-- astrona:playground:destroy -->`) or pages without commands.
- **Mermaid without HTML.** The platform renders Mermaid with HTML labels
  switched off, so `<br/>` and any other HTML tag break the drawing. Rules:
  - One line per box, no `<br/>`, no HTML. Keep the box to the thing's name
    (`"scout-v2"`, `"istiod"`, `"Service: scout"`).
  - Put the logic on the arrows: `E -->|"version: v2"| P2`,
    `I -->|"CDS"| C`, `A -->|"end-user: jason"| B`. Keep edge labels short.
  - Quote every label. Prefer `flowchart TB`; use `LR` only for a short chain.
  - Sequence diagrams: short participant aliases (`participant S as shuttle`)
    and short message text.
  - Anything longer (cluster names, full hostnames) goes in the sentence under
    the diagram.
- **Every course starts with an Introduction.** It lives in `sections/intro/`
  and is the first entry in `astrona.yaml` (`id: module-intro`, title
  "Introduction"). It has exactly these four pages, in this order:
  - `README.md`, `# Introduction`: what the introduction covers and its three
    pages, named in prose (no links), ending with the topic the course starts
    with.
  - `course-01-welcome.md`, `# Welcome To The Course`: who the course is for,
    the exam domain and what the reader can do at the end, the words the
    course uses, the example app, how the course is laid out and how to read
    a page.
  - `course-02-get-your-machine-ready.md`, `# Get Your Machine Ready`: the
    tools to install, the `astrona` commands used every day, and what to do
    when a start goes wrong.
  - `course-03-how-this-course-is-made.md`, `# How This Course Is Made`: how
    content is written and checked, the maintainers, how to report a mistake,
    and the license.
  The Introduction teaches no product content and has no playground, labs or
  summary. Its only links are the repository's contributors page, issues
  page and license.
- **No links to other course files.** A course page (every reading listed in
  `astrona.yaml`, the playground guide `docs/overview.md`, and a lab's
  `question.md` and `solution.md`) never links to or points the reader at
  another page or file of the repository: no links to parts, summaries,
  labs, `question.md`, other modules, sections or the Introduction, and no
  "see `practice.md`" or "open `config.yaml`". The platform shows the pages in
  the order of `astrona.yaml`, so a link only adds a second, often wrong,
  path. Name a thing in plain words when the reader needs it ("the task is on
  the next page"), and state a fact on the page itself instead of sending the
  reader somewhere else. Repository files for authors (the root `README.md`,
  a lab's or playground's `README.md`) may link.
- **No links to outside sources.** Course pages, labs and playground docs do
  not link to or point at outside websites (the one exception is the
  `resources` field of a lab entry in `astrona.yaml`) (official docs, GitHub, blogs,
  RFCs), and they have no "Reference" or "Official docs" lists. Everything the
  reader needs is explained on the page itself. Not affected: addresses the
  reader actually uses in a command or browser (`http://127.0.0.1:9080`,
  `curl https://httpbin.org`), and the Introduction's contributors and
  "report a mistake" links.
- **Configuration goes to a file first.** Whenever the reader should apply
  YAML (course parts, playground docs, labs), use three separate steps:
  1. "Save this as `virtualservice-scout.yaml`:" followed by a plain
     ` ```yaml ` block with only the YAML. No `cat > file <<'EOF'`, no
     `kubectl apply -f - <<EOF`, no shell around it.
  2. "Apply it:" followed by a ` ```sh ` block with only
     `kubectl apply -f virtualservice-scout.yaml`.
  3. "Then check the result:" followed by the check commands, if any.
  The file name says the kind and the object. If a value must come from the
  reader's cluster (an IP address), use a placeholder like `<PARTNER>` in the
  YAML and say how to get the value (`echo $PARTNER`); never put shell
  variables inside YAML. Apply an object the first time its YAML appears; do
  not show it once "to read" and paste it again later. Never tell the reader
  to apply something from the playground's `examples/` folder: they start the
  playground with `astrona run`, so that folder is not on their machine.
- **Helpers have readable names.** Shell helper functions and variables use
  names that say what they do (`check_route`, `count_versions`,
  `$SERVICE_URL`), never single letters.


## About this repo (ATS096 only)

Everything above is general and can be copied to other course repositories. This
section is only true for this one.

### What the student is trying to learn

- **The goal:** master the **Kustomize & Helm Controller Reconciliation**
  domain of the **FluxCD** training path (`ATP019`). It is 25% of the path,
  the largest domain. There is no official Flux certification exam; the
  path's domains and weights are Astrona's own, set in `ATP019/path.yaml`.
- **What the domain really tests:** delivering applications with Flux and
  keeping them in the state Git describes. The student must *do* things
  (shape a build with `targetNamespace`, patches and variable substitution,
  order deployments with `dependsOn`, gate them with health checks, install
  and upgrade a Helm chart with a `HelmRelease`, survive a failed upgrade,
  and prove that Flux reverts a manual change). Every explanation should lead
  to a command they can run, and every fix should be proved with an object
  that becomes `Ready` and a workload that answers with the expected values.
- **The four topics:** the Flux `Kustomization` in depth, dependencies and
  health checks, the `HelmRelease`, and drift detection, correction and
  pruning. The README table maps each section to its topic.
- **The sections:**

  | Section | Title | Topic |
  | --- | --- | --- |
  | 010 | The Flux Kustomization In Depth | Building and shaping what Flux applies |
  | 020 | Dependencies And Health Checks | Ordering and gating |
  | 030 | Deploying Helm Charts With HelmRelease | Helm delivery and remediation |
  | 040 | Drift Detection, Correction And Pruning | Keeping the cluster equal to Git |

- **The version:** everything is written for **Flux v2.9.6** (CLI and
  controllers) on a single-node `kind` cluster, with the podinfo Helm chart
  **6.15.0**. Flux 2.9 supports Kubernetes 1.34.1 or later. Do not teach
  fields, flags or output from other versions without saying so.
- **The main sources:** the Flux documentation, <https://fluxcd.io/flux/>,
  above all the `Kustomization` and `HelmRelease` API pages. Check every page
  against them.

### Status: built, not yet run

The first version of this repository was written from the Flux v2.9
documentation **without a live run**. No playground or lab has been started,
and no `astrona test` has passed yet. Until a maintainer runs them:

- Pages describe results in words. Do not add `text` output blocks until the
  output comes from a real run, and then paste it exactly.
- Treat every lab as unverified. Run `astrona validate` and `astrona test` on
  each one, one cluster at a time, before the course goes past `maturity:
  draft`.
- Remove this subsection when every lab has passed `astrona test`.

The biggest open risk is **Git credentials over plain HTTP**, the same as in
ATS094. The Flux documentation describes basic authentication for HTTPS only,
and the repository `gitops/fleet` is private, so every `GitRepository` sends
the `gitops` credentials to `http://gitea.localtest.me:3000`. If
source-controller or `flux create secret git` refuses that, every environment
fails at the first fetch. Check this first; the fallback is Gitea on HTTPS
with a self-signed certificate (`caFile` in the Secret).

The second risk is **outbound internet for Helm**. Section 030 and section
040 pull the podinfo chart from `https://stefanprodan.github.io/podinfo` and
`oci://ghcr.io/stefanprodan/charts/podinfo`. Without internet, those
`HelmRepository` and `OCIRepository` objects never become ready.

### Terms, not metaphors

Explanations use Flux's, Kustomize's, Helm's and Kubernetes' own words.
Define each one in plain technical language on first use in a file, for
example:

| Term | First-use definition (example wording) |
| --- | --- |
| Flux `Kustomization` | The Flux object `kustomize.toolkit.fluxcd.io/v1` `Kustomization`: it tells kustomize-controller which folder of a source to build and apply |
| Kustomize file `kustomization.yaml` | The Kustomize configuration file in a folder; it lists resources, patches and generators. Not the same thing as the Flux object |
| Kustomize | The tool that builds a set of YAML files into final manifests; `kubectl kustomize` runs it, and kustomize-controller has it built in |
| Overlay | A folder or Flux `Kustomization` that reuses a base and changes it for one environment |
| `targetNamespace` | A Flux `Kustomization` field that sets the namespace of every namespaced object it applies; the namespace must already exist |
| Patch | A change applied to built objects: a strategic merge patch (a partial object) or a JSON6902 patch (a list of operations on paths) |
| Variable substitution (`postBuild`) | kustomize-controller replaces `${name}` in the built YAML with values from `substitute` or from ConfigMaps and Secrets in `substituteFrom` |
| Server-side apply (SSA) | The Kubernetes API way to apply an object where the API server tracks which field manager owns which field |
| Field manager | The name the API server records as the owner of a field, for example `kustomize-controller` or `kubectl-edit` |
| `dependsOn` | A list of objects that must be `Ready` before this one is reconciled |
| Health check | The check that applied objects really work: `wait: true` for everything applied, `healthChecks` for a list, `healthCheckExprs` for custom resources with Common Expression Language (CEL) rules |
| `HelmRepository` / `OCIRepository` | A source of Helm charts: an HTTP chart repository with an `index.yaml` / an Open Container Initiative (OCI) registry |
| `HelmChart` | The object that holds one chart, fetched by source-controller; helm-controller creates it from `spec.chart` |
| `HelmRelease` | The Flux object `helm.toolkit.fluxcd.io/v2` `HelmRelease`: it tells helm-controller which chart to install, with which values |
| Release | One installed copy of a chart, with a revision number; Helm stores each revision as a Secret in the target namespace |
| Remediation | What helm-controller does after a failed install or upgrade: retry, roll back or uninstall |
| Drift detection (Helm) | helm-controller compares the live objects with the release manifest and reports (`warn`) or corrects (`enabled`) differences |
| Inventory | The list of objects a Flux `Kustomization` applied, in `.status.inventory`; pruning deletes what is in the inventory and no longer in Git |

The `Kustomization` name clash confuses every learner. On first use in a
file, always say which one you mean: "the Flux `Kustomization` object" or
"the Kustomize file `kustomization.yaml`".

### The example workloads

| Name | Image | What it is |
| --- | --- | --- |
| `gitea` (Deployment and Service `gitea-http`, namespace `gitea`) | `gitea/gitea:28.2.0-rootless` | The in-cluster Git server. HTTP on port `3000`. SQLite storage on an `emptyDir`, so a restart loses every repository |
| Gitea user `gitops` | | Password `gitops-password`, administrator. Lab-only credentials; say so when a page uses them |
| Repository `gitops/fleet` | | The cluster's Git repository. Every module seeds it with its own starting files |
| `podinfo` (Deployment and Service) | `ghcr.io/stefanprodan/podinfo:6.15.0` | The demo application, port `9898`. Its JSON answer has a `message` field set from `PODINFO_UI_MESSAGE` (manifests) or `ui.message` (chart) |
| `redis` (Deployment and Service, namespace `infrastructure`) | `redis:7.4-alpine` | A cache that podinfo uses in section 020, to show an infrastructure dependency |
| podinfo Helm chart | `https://stefanprodan.github.io/podinfo`, chart `podinfo` `6.15.0` (also `oci://ghcr.io/stefanprodan/charts/podinfo`) | Sections 030 and 040 |
| `tester` (namespace `gitea`) | `nicolaka/netshoot:v0.13` | Client pod with `curl` and `jq`. Graders call the Gitea API and podinfo from here; Git work happens on the reader's machine |

Environments use these namespaces: `podinfo-staging` and
`podinfo-production` (the two environments of the same application),
`infrastructure` (section 020) and `flux-system`. The playground or seed
script creates the two podinfo namespaces, because `targetNamespace` never
creates a namespace.

The repository layout follows the Flux convention:

```text
fleet/
├── apps/podinfo/base/     # deployment.yaml, service.yaml, kustomization.yaml, with ${variables}
├── infrastructure/redis/  # section 020 only
└── clusters/kind/         # what Flux reconciles for this cluster
```

Flux objects (`GitRepository`, Flux `Kustomization`, `HelmRepository`,
`HelmRelease`) are applied with `kubectl apply` from files the reader saves,
as in the other courses of this path, so that each page shows the whole
object. Say once per module that a real cluster keeps them in Git under
`clusters/<name>/`.

### Environment facts the text must respect

- **One Git address that works everywhere: `http://gitea.localtest.me:3000`.**
  The public DNS name `gitea.localtest.me` resolves to `127.0.0.1`. On the
  reader's machine, `kubectl -n gitea port-forward svc/gitea-http 3000:3000`
  makes Gitea answer there. Inside the cluster, the bootstrap adds a CoreDNS
  `rewrite stop` block so the same name resolves to
  `gitea-http.gitea.svc.cluster.local`, and rewrites the answer name back to
  `gitea.localtest.me` (Go programs, Flux included, ignore an answer whose name
  differs from the question). Copy the block from
  `sections/section-010/module-01/playground/bootstrap/prepare.sh`; never the
  one-line `rewrite name` form. Some home routers block DNS answers that point
  at `127.0.0.1`; then the reader adds `127.0.0.1 gitea.localtest.me` to
  `/etc/hosts`. Every page that clones says so in one sentence.
- **The port-forward must be running** for every `git` command on the
  reader's machine. Controllers inside the cluster do not need it.
- **Every environment starts with Flux installed** (`flux install`), the
  Secret `fleet-auth` and the `GitRepository` `fleet` (branch `main`,
  interval `1m`) already `Ready`. What the module adds on top is the
  material.
- **Flux CLI on the reader's machine.** Playgrounds and labs install `flux`
  2.9.6 from the GitHub release tarball into `/usr/local/bin` or
  `~/.local/bin`. The `helm` command is not installed; pages read release
  history from the `HelmRelease` status and from Helm's storage Secrets.
- **Flux facts (from the documentation, not yet seen on a run):**
  - Flux `Kustomization`: `interval` is required (60 seconds minimum
    recommended), `prune` is required, `retryInterval` defaults to
    `interval`. `targetNamespace` does not create the namespace.
    `patches` is a list of `patch` plus `target`. `postBuild.substitute` and
    `postBuild.substituteFrom` (`kind` `ConfigMap` or `Secret`, `optional`
    defaults to `false`, so a missing object fails the reconciliation).
    `${var:=default}` gives a default; `$${var}` keeps a literal; the
    annotation or label `kustomize.toolkit.fluxcd.io/substitute: disabled`
    turns substitution off for one object.
  - `dependsOn` waits for the `Ready` condition of each named object. `wait:
    true` health-checks everything applied and makes `healthChecks` ignored.
    `healthCheckExprs` entries have `apiVersion` (only the group is matched),
    `kind`, `current`, `inProgress`, `failed`, evaluated in the order
    `inProgress`, `failed`, `current`.
  - `deletionPolicy`: `MirrorPrune` (default), `Delete`,
    `WaitForTermination`, `Orphan`. `force: true` recreates objects whose
    immutable fields changed.
  - Annotations on objects in Git: `kustomize.toolkit.fluxcd.io/ssa`
    (`Override` default, `Merge`, `IfNotPresent`, `Ignore`),
    `kustomize.toolkit.fluxcd.io/prune: disabled`,
    `kustomize.toolkit.fluxcd.io/force: enabled`,
    `kustomize.toolkit.fluxcd.io/reconcile: disabled`.
  - Ready reasons of a Flux `Kustomization`: `ReconciliationSucceeded`, or
    `PruneFailed`, `ArtifactFailed`, `BuildFailed`, `HealthCheckFailed`,
    `DependencyNotReady`, `ReconciliationFailed`. Inventory entry ids are
    built from namespace, name, group and kind joined with `_` (core group
    empty, for example `podinfo-staging_podinfo__Service`); the docs also
    mention a version part. Graders match the id by prefix, so either form
    passes.
  - `HelmRelease` (`helm.toolkit.fluxcd.io/v2`): exactly one of `spec.chart`
    (a template for a `HelmChart`, with `chart`, `version`, `sourceRef`,
    `interval`) or `spec.chartRef` (`kind` `OCIRepository` or `HelmChart`).
    `valuesFrom` entries: `kind`, `name`, `valuesKey` (default
    `values.yaml`), `targetPath`, `optional` (default `false`).
    `releaseName` defaults to `[<targetNamespace>-]<name>`; the examples set
    it explicitly. `install.remediation.retries` and
    `upgrade.remediation.retries` default to `0`;
    `upgrade.remediation.strategy` is `rollback` (default) or `uninstall`;
    `remediateLastFailure` defaults to `false` unless `retries` is greater
    than `0`. `timeout` defaults to `5m0s`.
  - `HelmRelease` conditions: `Ready`, `Released`, `Remediated`,
    `TestSuccess`, `Stalled` (reason `RetriesExceeded`), `Drifted`
    (`DriftDetected` or `NoDriftDetected`). `driftDetection.mode` is `warn`
    or `enabled`; `driftDetection.ignore` entries have JSON Pointer `paths`
    and an optional `target`.
  - Helm stores each release revision as a Secret
    `sh.helm.release.v1.<release>.v<N>` with the labels `owner=helm`,
    `name=<release>` and `status` (`deployed`, `superseded`, `failed`). This
    is Helm's behaviour, not Flux's; graders use it to prove a rollback.
- **Many environments start broken on purpose.** A lab seeds a fault in Git
  or in the cluster. The fault is the material. Never "fix" it in the
  bootstrap.
- **The proof is the cluster matching Git.** A fix is proven with `flux get`
  showing `Ready True`, plus the workload itself: a request to podinfo from
  `tester` that returns the expected `message`, or `kubectl get` with the
  expected replica count. Where a page tests drift correction, it changes the
  live object and runs `flux reconcile` instead of waiting.

### Where things are in this repo

| What | Where |
| --- | --- |
| Course outline the platform reads: every reading page and lab, in order. Never list `solution.md` here | `astrona.yaml` |
| Overview, sections and modules tables, how to run things | `README.md` |
| Introduction (see "Every course starts with an Introduction") | `sections/intro/` |
| Section overview and its modules | `sections/section-0N0/README.md` |
| Module reading: landing page, deep-dive parts, closing page | `sections/section-0N0/module-0M/course.md`, `course-0N-*.md` |
| Graded lab: task, walkthrough, setup, grader | `.../labs/lab-01/` (`question.md`, `solution.md`, `prerequisites.md`, `bootstrap/`, `manifests/`, `solution/`, `testing/`, `validation/`) |
| Ungraded sandbox for a module | `.../playground/` (`config.yaml`, `bootstrap/prepare.sh`, `manifests/`, `docs/overview.md`, which is the only learner page) |
| One graded integration lab per section | `sections/section-0N0/capstone/labs/lab-01/` |

A lab folder holds:

| Path | Purpose |
| --- | --- |
| `config.yaml` | Lab definition; `metadata.docs` points at `question.md` and `solution.md` |
| `README.md` | Short intro for authors with `estimated_duration` front matter and the run, submit and destroy commands |
| `prerequisites.md` | What the learner needs before starting |
| `question.md` | The task. Starts with `# Question` and `Solve this question on: \`terminal\`` |
| `solution.md` | Step-by-step walkthrough |
| `bootstrap/01-install-git-and-flux.sh`, `02-seed-state.sh` | Gitea, the CoreDNS rewrite, the Flux CLI, `flux install`, the `GitRepository` `fleet`, and the starting state |
| `manifests/` | `lab-start.yaml` (Gitea and tester), `repo/` (files seeded into `gitops/fleet`), `source.yaml` (the `fleet` source) and any starting Flux objects |
| `solution/apply.sh` | Reference end state, applied only by `astrona test` |
| `testing/wait-for-flux.sh` | Waits until Gitea and the Flux controllers answer before the reference solution runs |
| `validation/validate-*.sh` | Behavioural grading, one script per check |

The shared plumbing (`lab-start.yaml`, `01-install-git-and-flux.sh`,
`prepare.sh`, `wait-for-flux.sh`, `source.yaml`) is the same in every
environment apart from names. When you change it, change it everywhere.

### Lab metadata in `astrona.yaml`

`astrona.yaml` has a `training:` block (id `ATS096`, domain
`Kustomize & Helm Controller Reconciliation`, weight `25`) and one entry per
section under `modules:` (`module-010` to `module-040`). Each section's
`content` lists, in order: the section `README.md`, then for each module its
landing page, its parts, and right after the part a lab tests, a `Question`
reading (`labs/lab-01/question.md`) followed by the `type: lab` entry; the
module's closing page comes last. The section capstone closes the section.
Playgrounds are not listed.

Every `type: lab` entry carries the same fields, in the same order, as in
ATS016: `title`, `path`, `difficulty`, `estimated_duration`, `topic`,
`task_kind`, `tags`, `learning_goals`, `resources`.

- `difficulty`: `beginner`, `intermediate` or `advanced`.
- `estimated_duration`: realistic time to solve it, for example `20m`, `35m`.
- `topic`: exactly one of `kustomize-build`, `dependencies`,
  `health-checks`, `helm-release`, `remediation`, `drift`.
- `task_kind`: exactly one of `build`, `troubleshooting` or `migration`.
- `tags`: 4 to 8 ids, only from the tag list below. Add a new tag to the list
  first if nothing fits.
- `learning_goals`: 2 or 3 plain sentences, each starting with a verb.
- `resources`: 1 to 4 pages on `fluxcd.io`, each with a `name` and a `url`
  that loads. This is the **only** place outside links are allowed.

**Tag list** (lower case, hyphens, never synonyms):

- Build: `kustomization`, `kustomize-file`, `target-namespace`, `patches`,
  `post-build-substitution`, `substitute-from`, `flux-build`, `flux-diff`
- Ordering and health: `depends-on`, `wait`, `health-checks`,
  `health-check-exprs`, `timeout`, `staged-rollout`
- Helm: `helmrelease`, `helmrepository`, `ocirepository`, `chart-ref`,
  `values-from`, `remediation`, `rollback`, `helm-storage`
- Drift and pruning: `drift-detection`, `drift-correction`,
  `server-side-apply`, `ssa-annotation`, `prune`, `inventory`,
  `deletion-policy`
- CLI: `flux-get`, `flux-events`, `flux-reconcile`

### Running things

```bash
# Playground (ungraded)
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-010/module-01/playground
astrona destroy ats-096-playground-010-01   # takes metadata.name from config.yaml, not the path

# Lab or capstone (graded against the live cluster)
astrona run --git ssh://git@github.com/astrona-io/ATS096.git -c sections/section-010/module-01/labs/lab-01
astrona submit -c sections/section-010/module-01/labs/lab-01
astrona destroy ats-096-lab-010-01

# Authors: run a local, uncommitted copy, and prove a lab passes with its reference solution
astrona run -c sections/section-010/module-01/playground
astrona test -c sections/section-010/module-01/labs/lab-01
```

Names: a playground is `ats-096-playground-<section>-<module>`, a module lab
is `ats-096-lab-<section>-<module>` and a capstone is
`ats-096-capstone-<section>`; keep those names. Lab bootstrap scripts do not
pin a kube context: astrona sets `KUBECONFIG` for the lab. Every lab must pass
`astrona validate` and `astrona test`.

Graders check **behaviour**, not just that an object exists: a `Ready`
condition, the workload answering with the expected `message` and replica
count, a dependency that really holds back the next stage, a rollback
recorded in Helm's storage, and drift put back by Flux. Graders also reject
the plausible but wrong fix (`kubectl apply` of the application by hand,
suspending the failing object, removing `dependsOn` to unblock a pipeline,
switching drift detection off, setting `optional: true` to hide a missing
values source). A lab's `question.md` and `solution.md` must match what its
`validation/` scripts actually check.

Test clusters on the maintainer's machine: one at a time. Each environment
runs Gitea plus four Flux controllers and two copies of podinfo.

### Where to find trusted sources

Check facts here before writing them down. Prefer these over memory.

- **APIs:** [Kustomization](https://fluxcd.io/flux/components/kustomize/kustomizations/),
  [HelmRelease](https://fluxcd.io/flux/components/helm/helmreleases/),
  [HelmRepository](https://fluxcd.io/flux/components/source/helmrepositories/),
  [OCIRepository](https://fluxcd.io/flux/components/source/ocirepositories/),
  [HelmChart](https://fluxcd.io/flux/components/source/helmcharts/)
- **Guides:** [Helm releases](https://fluxcd.io/flux/guides/helmreleases/),
  [repository structure](https://fluxcd.io/flux/guides/repository-structure/)
- **CLI:** [flux build kustomization](https://fluxcd.io/flux/cmd/flux_build_kustomization/),
  [flux diff kustomization](https://fluxcd.io/flux/cmd/flux_diff_kustomization/),
  [flux command reference](https://fluxcd.io/flux/cmd/)
- **Kubernetes:** [server-side apply](https://kubernetes.io/docs/reference/using-api/server-side-apply/)

### Skills to use here

The `astrona-course-*` skills do most authoring jobs in this repository:
planning (`domain-plan`), creating the tree (`domain-scaffold`), building
modules (`domain-build`), deep-dive parts (`deep-dive`), labs and playgrounds
(`lab`), lab docs (`lab-docs`), challenges (`create-challenge`), quizzes
(`generate-assessment`) and fact-checking (`review-accuracy`).
