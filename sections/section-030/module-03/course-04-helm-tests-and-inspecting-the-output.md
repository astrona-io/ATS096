# Helm Tests And Inspecting The Output

Two questions remain once a release is installed. Does the chart work, and what exactly did Helm install? A chart can ship tests that helm-controller runs for you. And Helm stores every release as a Secret, which holds the merged values and the rendered manifest. This part runs the tests of podinfo and decodes the Secret.

## Chart tests

A Helm test is a Pod in the chart, marked with the annotation `helm.sh/hook: test`. It runs to completion and its exit code is the result. The podinfo chart ships such tests. Helm runs them only on request, and in Flux the request is the field `spec.test`:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"test":{"enable":true}}}'
flux reconcile helmrelease podinfo -n podinfo-staging
flux get helmreleases -n podinfo-staging
kubectl -n podinfo-staging get pods
```

With `enable: true`, helm-controller runs the tests after an install or an upgrade. A failing test makes the release not ready with a test failure, and the remediation settings from the earlier module apply. `ignoreFailures: true` records a failed test but keeps the release ready, which fits a test that is known to be flaky. Test Pods stay in the namespace until the next test run, so a failing one can be read with `kubectl logs`.

The tests run only on a new install or upgrade. Changing `test.enable` alone does not start them; the patch above works because the reconcile after it finds a spec that differs from the last release and upgrades it.

## Helm's storage

Helm records each revision of a release in a Secret of the type `helm.sh/release.v1` in the namespace of the release. The name is `sh.helm.release.v1.<release>.v<revision>`, and the labels include `owner=helm` and `name=<release>`:

```sh
kubectl -n podinfo-staging get secrets -l owner=helm,name=podinfo -L version,status
```

You see one Secret for each revision, the status `deployed` for the current one and `superseded` for older ones.

## Decode the rendered manifest

The key `release` holds the revision as JSON that is compressed with gzip and encoded with base64. Kubernetes encodes the Secret data once more. To read it, decode twice, then decompress:

```sh
kubectl -n podinfo-staging get secret sh.helm.release.v1.podinfo.v1 -o jsonpath='{.data.release}' | base64 -d | base64 -d | gunzip | jq -r .manifest
```

The output is the YAML Helm installed for revision 1. Change the last part to see the values the release was given:

```sh
kubectl -n podinfo-staging get secret sh.helm.release.v1.podinfo.v1 -o jsonpath='{.data.release}' | base64 -d | base64 -d | gunzip | jq .config
```

Use the revision number of the revision you want. The `manifest` is what was installed after the post-renderers ran, so it is the place to check whether a patch took effect.

Secrets are readable by anyone with access to the namespace, and `config` holds the values the release was given, including those taken from Secrets. Treat these Secrets as sensitive.

You can now run the tests of a chart and read exactly what a release installed. These two checks close the loop of the module: values go in, the chart is rendered and rewritten, and the storage shows the result.

## Common pitfalls

> [!WARNING]
> - **Enabling tests and expecting an instant run.** Tests run with an install or an upgrade.
> - **Decoding once.** Kubernetes adds a layer of base64, and the release adds another.
> - **Sharing the output of `.config`.** It can contain secrets that came from `valuesFrom`.
> - **Reading the chart's templates instead of `manifest`.** Only the manifest shows what was installed.
