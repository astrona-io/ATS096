# Source Kinds And Cross-Namespace References

A Flux `Kustomization` does not fetch anything by itself. It reads the artifact that a **source** object produced, and `spec.sourceRef` says which source. So far that source has been a `GitRepository`. kustomize-controller accepts three source kinds, and it can read a source from another namespace. This part compares the kinds, applies from an OCI artifact, and shows what a cross-namespace reference allows.

## The three source kinds

The source objects belong to source-controller, with the API group `source.toolkit.fluxcd.io`. Each one downloads something, packs it as an artifact and stores it. The Flux `Kustomization` then downloads that artifact from source-controller.

| Kind | Where the files come from | How a version is chosen |
| --- | --- | --- |
| `GitRepository` | A Git server, over HTTPS or SSH | `ref.branch`, `ref.tag`, `ref.semver` or `ref.commit` |
| `OCIRepository` | An OCI registry, as an artifact pushed with `flux push artifact` | `ref.tag`, `ref.semver` or `ref.digest` |
| `Bucket` | An S3-compatible bucket, or a bucket of Google Cloud Storage or Azure Blob Storage | The content of the bucket; the revision is a digest of the files |

Which one to use depends on what you control. A Git server is the usual choice: the history is the audit trail. An OCI registry stores immutable, versioned artifacts, which suits a pipeline that builds the manifests once and promotes the same artifact through environments. A bucket suits teams that already publish files to object storage and do not want a Git server in the path.

The field `sourceRef` is the same for all three. Only `kind` and `name` change.

## Apply from an OCI artifact

The public registry `ghcr.io` holds an artifact with the manifests of podinfo. Save this as `podinfo-oci.yaml`:

<!-- astrona:playground:renew -->

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: OCIRepository
metadata:
  name: podinfo-manifests
  namespace: flux-system
spec:
  interval: 5m
  url: oci://ghcr.io/stefanprodan/manifests/podinfo
  ref:
    semver: ">= 6.0.0"
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-oci
  namespace: flux-system
spec:
  interval: 10m
  path: ./
  prune: true
  targetNamespace: podinfo-production
  sourceRef:
    kind: OCIRepository
    name: podinfo-manifests
```

```sh
kubectl apply -f podinfo-oci.yaml
flux get sources oci
flux get kustomizations
kubectl -n podinfo-production get deployment
```

The `OCIRepository` shows a revision made of the chosen tag and the digest of the artifact. The Flux `Kustomization` builds the artifact with `path: ./` and applies the result into `podinfo-production`. The only change from a Git setup is the `kind` in `sourceRef` and the source object itself.

Inspect which artifact the Flux `Kustomization` applied:

```sh
kubectl -n flux-system get kustomization podinfo-oci -o jsonpath='{.status.lastAppliedRevision}'
```

The value is the revision of the source at the time of the last apply. For a Git source it holds the branch and the commit, and for an OCI source it holds the tag and the digest.

To publish your own artifact, push a folder to a registry you can write to. This needs a registry and credentials, so it is not part of the playground:

```sh
flux push artifact oci://registry.example.com/manifests/podinfo:1.0.0 \
  --path=./apps/podinfo \
  --source="$(git config --get remote.origin.url)" \
  --revision="$(git rev-parse HEAD)"
```

## A Bucket as a source

A `Bucket` names an endpoint, a bucket, and optionally a Secret with the access keys. This example describes a MinIO-style endpoint. Do not apply it in the playground, because no bucket exists:

```yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: Bucket
metadata:
  name: team-manifests
  namespace: flux-system
spec:
  interval: 5m
  provider: generic
  bucketName: manifests
  endpoint: minio.example.com:9000
  secretRef:
    name: team-manifests-keys
```

A Flux `Kustomization` then uses `kind: Bucket` and `name: team-manifests` in `sourceRef`. The bucket has no history, so a rollback means putting the old files back.

## Cross-namespace references

The source above and its Flux `Kustomization` are in the same namespace. The field `sourceRef.namespace` lets a Flux `Kustomization` read a source from a different one. That is useful when a platform team owns one shared source in `flux-system` and application teams own their own Flux `Kustomization` objects in their own namespaces.

Create a namespace for a team and apply a Flux `Kustomization` there that uses the shared source. Save this as `team-a.yaml`:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: team-a
---
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: podinfo-team-a
  namespace: team-a
spec:
  interval: 10m
  path: ./
  prune: true
  targetNamespace: podinfo-staging
  sourceRef:
    kind: OCIRepository
    name: podinfo-manifests
    namespace: flux-system
```

```sh
kubectl apply -f team-a.yaml
flux get kustomizations --all-namespaces
kubectl -n podinfo-staging get deployment
```

The list shows `podinfo-oci` in `flux-system` and `podinfo-team-a` in `team-a`, both reading the same `OCIRepository`.

## Why this needs a rule

A cross-namespace reference crosses a trust boundary. If any team can name any source in any namespace, a Flux `Kustomization` in `team-a` can apply files that belong to another team. Cluster administrators can switch the behavior off with the controller flag `--no-cross-namespace-refs`. With the flag set, a Flux `Kustomization` that names a source in another namespace does not reconcile, and its status reports an error. The flag is set when Flux is installed, and it applies to every Flux `Kustomization` in the cluster. In a cluster shared by teams, set it together with a `serviceAccountName` per Flux `Kustomization`, so that a team's objects are limited both in what they read and in what they change.

Check what you can: `flux get sources oci` lists sources of one kind, and `flux get sources all` lists every kind in one table.

## Common pitfalls

> [!WARNING]
> - **Leaving out `sourceRef.namespace` for a source in another namespace.** The name is then looked up in the namespace of the Flux `Kustomization` and not found.
> - **Using `path: ./apps/podinfo` with an OCI artifact that was pushed from that folder.** The artifact root is the pushed folder, so the path is `./`.
> - **Pushing a mutable tag such as `latest` and expecting a clean rollback.** A tag can move. Use a version tag or a digest for anything that must be repeatable.
> - **Creating the access Secret in the wrong namespace.** The `secretRef` of a source is read from the namespace of the source object, not from the namespace of the Flux `Kustomization`.
> - **Assuming a `Bucket` keeps history.** It holds the current files only.
