# Summary

Every live object records which manager owns which field in `metadata.managedFields`. A server-side apply records `Apply`, a plain write records `Update`, and the `fieldsV1` tree lists the owned fields. Flux owns exactly the fields that are in the YAML it applies, and it applies with force, so a field that Git sets is taken back at each reconciliation.

To give a field to another writer, such as an autoscaler, remove it from Git. The field then leaves Flux's claim, returns to its default once, and stays wherever the other writer sets it. A second applier that disagrees with the owner gets a conflict error, and `--force-conflicts` takes the field only until Flux applies again. Immutable fields need `kustomize.toolkit.fluxcd.io/force: enabled` on one object, or `spec.force: true` for the whole stage, and both recreate objects.

The exceptions run from narrow to wide: remove a field from Git, `flux-client-side-apply` for an added field, the `ssa` annotation values, `reconcile: disabled`, and `suspend`. Choose the narrowest that works, write down the reason, and check the size of the exception with `flux diff` and the managed fields.

- Flux owns what it sends.
- To free a field, stop sending it.
- Force beats a conflict, but Flux forces too.
- Keep exceptions in Git, narrow and explained.

<!-- astrona:playground:destroy -->
