---
estimated_duration: 40m
---

# Keep Two Environments Equal To Git

- **ID:** CAPSTONE
- **Slug:** ats-096-capstone-040
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded capstone

Graded capstone for section 040, in the namespaces `flux-system`, `podinfo-staging` and `podinfo-production`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This capstone was written from the Flux v2.9 documentation
> and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-096-capstone-040
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-096-capstone-040`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough with a submit loop |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Flux CLI, Gitea, CoreDNS rewrite, `flux install` and the `fleet` source, then the starting state |
| `manifests/` | `lab-start.yaml` (Gitea, tester), `repo/` (files seeded into `gitops/fleet`), `source.yaml`, `namespaces.yaml`, `staging.yaml`, `helm.yaml` |
| `solution/` | Reference solution used by `astrona test` |
| `testing/` | Waits for Gitea and the Flux controllers |
| `validation/` | Grading scripts, one per check |
