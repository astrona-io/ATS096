# Order And Gate Deployments With dependsOn And Health Checks — Playground

- **ID:** PLAYGROUND
- **Slug:** ats-096-playground-020-01
- **Author:** Paris Nakita Kejser
- **Type:** Astrona playground — clean environment, no task, no grading

> **Not yet run.** This playground was written from the Flux v2.9
> documentation and has not been started on a cluster yet.

A single sandbox environment that spins up and stays running so you can
explore the module's topic. Nothing to submit.

## Run it

```sh
astrona run -c .
astrona destroy ats-096-playground-020-01
```

`astrona destroy` takes the environment name (`metadata.name` = `ats-096-playground-020-01`), not
the config path. `astrona submit` and `astrona test` do not apply — there is no
grading.

## Layout

| Path | Purpose |
| --- | --- |
| `config.yaml` | Environment definition (runtime + bootstrap only) |
| `bootstrap/prepare.sh` | Flux CLI, Gitea, CoreDNS rewrite, `flux install`, the `fleet` source |
| `manifests/` | `lab-start.yaml` (Gitea, tester), `repo/` (files seeded into `gitops/fleet`), `source.yaml`, `namespaces.yaml` |
| `docs/overview.md` | What the environment contains and ideas to try |
