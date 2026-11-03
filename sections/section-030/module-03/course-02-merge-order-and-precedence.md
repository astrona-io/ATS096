# Merge Order And Precedence

A release can take values from the chart defaults, from several `valuesFrom` entries and from `spec.values`. When two of them set the same key, one wins. This part states the order, proves it with podinfo, and shows how to find out which value a release really used.

## The order

helm-controller builds the values document in this order, where each step overrides the one before it:

1. The defaults in the `values.yaml` file of the chart.
2. The files named in `valuesFiles`, for a chart from Git, in list order.
3. The entries of `valuesFrom`, in list order. A later entry overrides an earlier one.
4. `spec.values` in the release itself.

So `spec.values` always wins, and the last `valuesFrom` entry wins among the sources outside the release. Maps are merged key by key; a list is replaced as a whole, not merged.

## Prove it

Use the release of the previous part. Add `spec.values` with a different message and look at the answer:

<!-- astrona:playground:renew -->

```sh
kubectl -n podinfo-staging patch helmrelease podinfo --type=merge -p '{"spec":{"values":{"ui":{"message":"from spec.values"}}}}'
flux reconcile helmrelease podinfo -n podinfo-staging
kubectl -n gitea exec deploy/tester -- sh -c "curl -s http://podinfo.podinfo-staging:9898 | jq -r .message"
```

The message is `from spec.values`, although the ConfigMap still says something else. Now add a second ConfigMap and list it after the first:

```sh
kubectl -n podinfo-staging create configmap podinfo-values-late --from-literal=values.yaml='replicaCount: 2'
kubectl -n podinfo-staging patch helmrelease podinfo --type=json -p '[{"op":"add","path":"/spec/valuesFrom/-","value":{"kind":"ConfigMap","name":"podinfo-values-late"}}]'
flux reconcile helmrelease podinfo -n podinfo-staging
kubectl -n podinfo-staging get deployment podinfo
```

The second ConfigMap sets `replicaCount`, which the first does not mention. The maps are merged: the message stays, and the replicas become two.

## Why lists are different

If two sources set a list, for example `ingress.hosts`, the later one replaces the whole list. Nothing is appended. A chart that expects a list to be extended needs the whole list in the winning source.

## Which values were used

The release keeps the values it used in Helm's storage, and `status.history` shows the chart version and a digest of the values for each revision. To see the merged document itself, the part on inspecting the output decodes the storage Secret, where the user-supplied values are stored next to the rendered manifest.

You can now predict the winner of a value conflict and merge values from several places. The next part changes what the chart produces when no value reaches far enough.

## Common pitfalls

> [!WARNING]
> - **Setting a value in `valuesFrom` and in `spec.values`.** `spec.values` wins, and the ConfigMap edit seems to do nothing.
> - **Expecting a list to merge.** Lists are replaced.
> - **Reversing the list order.** The last `valuesFrom` entry wins, not the first.
> - **Forgetting the chart defaults.** A key you never set still has the value from the chart.
