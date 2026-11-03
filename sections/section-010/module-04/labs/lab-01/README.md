---
estimated_duration: 25m
---

# Decrypt A Secret With SOPS And Age

- **ID:** LAB
- **Slug:** ats-096-lab-010-04
- **Author:** Paris Nakita Kejser
- **Type:** Astrona graded lab

Graded lab, in the namespaces `flux-system` and `podinfo-staging`. Read `question.md` for the task; `solution.md` is the walkthrough.

> **Not yet run.** This lab was written from the Flux v2.9 documentation
> and has not passed `astrona test` yet.

## Run it

```sh
astrona run -c .
astrona submit
astrona destroy ats-096-lab-010-04
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-096-lab-010-04`), not
the config path.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition, bootstrap and grading |
| `question.md` | The task |
| `solution.md` | Step-by-step walkthrough with a submit loop |
| `prerequisites.md` | Assumed knowledge and what the environment provides |
| `bootstrap/` | Flux CLI, Gitea, CoreDNS rewrite, `flux install` and the `fleet` source, then age, sops, the key Secret, the encrypted file and the starting Flux Kustomization |
| `manifests/` | `lab-start.yaml` (Gitea, tester), `repo/` (files seeded into `gitops/fleet`), `source.yaml`, `namespaces.yaml`, `start.yaml` (the Flux Kustomization `podinfo-secure`) |
| `solution/` | Reference solution used by `astrona test`; it patches the Flux Kustomization |
| `testing/` | Waits for Gitea and the Flux controllers |
| `validation/` | Grading scripts, one per check |
