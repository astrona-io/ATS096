# Verifying And Authenticating Charts

A chart runs with the permissions of a Helm install. Two questions follow: did the chart come from the project that claims it, and can Flux read a repository that asks for a login. This part answers the first with signature verification for OCI charts, and the second with credentials in a Secret.

## Signed charts

A signature is a proof, stored next to the chart, that a known identity published exactly these bytes. cosign is the tool that creates and checks such signatures for OCI artifacts. In keyless mode, the identity is an account of an identity provider, and the proof is recorded in a public log. The podinfo project signs its chart this way from its build pipeline on GitHub.

source-controller checks a signature when the `OCIRepository` has a `verify` block. The block names the provider `cosign` and the identity it accepts, as a pattern for the issuer and the subject:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo-chart
  namespace: podinfo-staging
spec:
  interval: 1h
  url: oci://ghcr.io/stefanprodan/charts/podinfo
  ref:
    tag: 6.15.0
  layerSelector:
    mediaType: application/vnd.cncf.helm.chart.content.v1.tar+gzip
    operation: copy
  verify:
    provider: cosign
    matchOIDCIdentity:
      - issuer: ^https://token\.actions\.githubusercontent\.com$
        subject: ^https://github\.com/stefanprodan/podinfo.*$
```

Save it as `ocirepository-podinfo-chart.yaml`, apply it and check the result:

```sh
kubectl apply -f ocirepository-podinfo-chart.yaml
flux get sources oci -n podinfo-staging
kubectl -n podinfo-staging get ocirepository podinfo-chart -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.reason}{"\n"}{end}'
```

When the signature matches, the object is `Ready` and a condition says that the artifact was verified. When the artifact has no signature, or the subject does not match, the object is not ready and the message says that verification failed. Nothing is installed from an artifact that failed verification, because a `HelmRelease` with `chartRef` waits for a ready `OCIRepository`.

Change `subject` to a pattern that cannot match, such as `^https://github\.com/nobody/.*$`, apply again, and read the condition: the same artifact is now refused. The check depends entirely on the identity patterns you write, so keep them narrow.

## Charts from a repository that needs a login

A private chart repository answers with an error unless the request carries credentials. A `HelmRepository` takes them from a Secret in its namespace, named in `spec.secretRef`. The Secret is of the type `Opaque` with the keys `username` and `password`:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: charts-auth
  namespace: podinfo-staging
stringData:
  username: robot
  password: replace-me
```

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: HelmRepository
metadata:
  name: private-charts
  namespace: podinfo-staging
spec:
  interval: 10m
  url: https://charts.example.com
  secretRef:
    name: charts-auth
```

These two examples are not applied in the playground: the address does not exist. For an OCI registry, a `HelmRepository` with `type: oci` and `url: oci://...` uses the same `secretRef`, and `OCIRepository` has `secretRef` too. A Secret of the type `kubernetes.io/dockerconfigjson` is accepted there.

The password in a Secret is only encoded, not encrypted. A real cluster keeps such a Secret encrypted in Git, or created by an external secrets tool, so that it never appears in plain text in a commit.

You can now verify where an OCI chart came from and give a source the credentials it needs. Together with exact versions and the right reconcile strategy, you can control what source-controller delivers to a release.

## Common pitfalls

> [!WARNING]
> - **Patterns that are too wide.** `.*` as a subject accepts any identity. Match the account and the repository.
> - **Forgetting the dots in a pattern.** `.` matches any character. Escape it as `\.`.
> - **A `secretRef` in another namespace.** The Secret must be in the namespace of the source.
> - **Committing the Secret in plain text.** Encode is not encrypt.
