# Namespaces

Namespaces is kind of a critical resource in Kubernetes, it's very dangerous to delete a
namespace with some CRDs or PVs, it may stuck in `Terminating` status and never be
deleted.

So to be safe, we have to create all the namespaces we need in the `infra/namespaces`
folder, and declare that Flux2 should not prune theses namespaces when reconciling.

## Exclude Namespace from Helm Release

Some helm charts may create namespaces automatically, which will cause the namespace to be
deleted when the helm release is deleted, it's very dangerous.

To prevent this, we have to exclude the namespace from the helm release, and add the
namespace to the `infra/namespaces` folder.

To exclude the namespace from the helm release, here is an example:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: xxx
  namespace: xxx
spec:
  # ......
  postRenderers:
    - kustomize:
        patches:
        - patch: |-
            $patch: delete
            apiVersion: v1
            kind: Namespace
            metadata:
              name: xxx
