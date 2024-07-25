# FAQ

## 401: unauthorized - Helm charts fetched from an OCI Registry

This is a known issue, most likely because the URL path is miswritten, it needs to
separate the prefix part of the OCI URL from the image name.

## unable to locate any tags in provided repository: oci://xxx

A known issue too, the v prefix in oci image tags is not supported by Helm nor Flux, see
[flux2/issues/3766](https://github.com/fluxcd/flux2/issues/3766) for details.

To fix the issue, you have to rename the tag to remove the v prefix.

## Will Flux2 Overwrite My Existing Resources?

No, flux2 will refuse to deploy if there are existing resources with the same name in the
cluster. To get flux2 to overwrite the existing resources, you need to delete the existing
resources first.

## Will Flux2 Revert My Changes If I Manually Change The Resources via `kubectl`?

> https://fluxcd.io/flux/components/kustomize/kustomizations/#controlling-the-apply-behavior-of-resources

Yes, flux2 will revert your changes if you manually change the resources via `kubectl`.

You can control this behavior by add `kustomize.toolkit.fluxcd.io/ssa: Merge` to the
resource's annotation, to prevent flux2 from reverting the changes on the filed that is
not defined in Git repository. This is useful when you want to change `spec.replicas` of
some CRDs manually.

## Namespace stuck in `Terminating` status

> [Stop Messing with Kubernetes Finalizers](https://martinheinz.dev/blog/74)

> https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/

> https://stackoverflow.com/questions/52369247/namespace-stucked-as-terminating-how-i-removed-it

Deleting objects in Kubernetes can be challenging. You may think you’ve deleted something,
only to find it still persists.

Especially when you delete a namespace with some CRDs or PVs, it may stuck in
`Terminating` status and never be deleted.

For PV/PVC with `kubernetes.io/pv-protection` finalizer, you have to make sure the PV/PVC
is not needed anymore, and then delete the finalizer manually.

For CRDs provided by operators, you have to **delete the CRs first**, and then delete the
operators and namespace, otherwise the namespace will stuck in `Terminating` status! This
is because delete a CR will trigger the operator to delete the corresponding resources,
and if the operator is deleted before the CRs, the webhook will not work and the CRs will
fail to be deleted, and the namespace will stuck in `Terminating` status.

So we have to add our CRs into `infra/configs` folder, and declare that it's depends on
`infra/controllers` in the `kustomization.yaml` file, so that Flux2 will delete the CRs
first before the operators.

### Special Cases - Kubevirt

```bash
› kubectl describe ns cert-managear
...
  NamespaceDeletionDiscoveryFailure            True    Tue, 19 Mar 2024 01:12:15 +0800  DiscoveryFailed         Discovery failed for some groups, 2 failing: unable t
o retrieve the complete list of server APIs: subresources.kubevirt.io/v1: stale GroupVersion discovery: subresources.kubevirt.io/v1, subresources.kubevirt.io/v1alpha
3: stale GroupVersion discovery: subresources.kubevirt.io/v1alpha3
```

```bash
› kubectl get apiservice | grep False

v1.subresources.kubevirt.io                          kubevirt/virt-api            False (ServiceNotFound)   2d21h
v1alpha3.subresources.kubevirt.io                    kubevirt/virt-api            False (ServiceNotFound)   2d21h
```

Seems related to <https://github.com/kubevirt/kubevirt/issues/9725>.

Workaround:

```bash
kubectl delete apiservice v1.subresources.kubevirt.io
kubectl delete apiservice v1alpha3.subresources.kubevirt.io
```

And then wait for some minutes, the namespace will be deleted automatically.

### Special Cases - What if my operator has already been deleted?

Here we use `kubevirt` as an example, the workflow is similar for other operators(such as
longhorn).

Find what remains in the namespace:

```bash
› kubectl api-resources --verbs=list --namespaced -o name   | xargs -n 1 kubectl get --show-kind --ignore-not-found -n kubevirt

NAME                            AGE     PHASE
kubevirt.kubevirt.io/kubevirt   2d21h   Deployed
```

Since the operator has been deleted, we have to force delete the CRs, and remove cleanup
the resources manually.

Try to patch the CRs to remove the finalizer, but it will not work:

```bash
› kubectl patch --type merge --patch '{"metadata":{"finalizers":null}}' -n kubevirt kubevirt/kubevirt

Error from server (InternalError): Internal error occurred: failed calling webhook "kubevirt-validator.kubevirt.io": failed to call webhook: Post "https://kubevirt-operator-webhook.kubevirt.svc:443/kubevirt-validate-delete?timeout=10s": service "kubevirt-operator-webhook" not found
```

Remove kubevirt's `ValidatingWebhookConfiguration` and `MutatingWebhookConfiguration`
manually to skip the webhook validation:

```bash
› kubectl get validatingwebhookconfiguration | grep virt
virt-api-validator                               19         2d21h
virt-operator-validator                          3          2d21h

› kubectl delete validatingwebhookconfiguration virt-api-validator virt-operator-validator

# and then do the same for mutatingwebhookconfiguration
```

```bash
kubectl patch --type merge --patch '{"metadata":{"finalizers":null}}' -n kubevirt kubevirt/kubevirt

# If you have too much protected resources,
# and you're pretty sure that you don't need them anymore,
# you can force delete them all:
RES=$(kubectl api-resources --verbs=list --namespaced -o name   | xargs -n 1 kubectl get --show-kind --ignore-not-found -n kubevirt | grep -v NAME | awk '{print $1}')
kubectl patch --type merge --patch '{"metadata":{"finalizers":null}}' -n kubevirt $RES
```

Then the namespace will be deleted automatically.

### How to create pvc using existing pv?

1. The PV should have its `spec.persistentVolumeReclaimPolicy` set to `Retain`, otherwise
   it will be deleted automatically after the PVC is deleted.
1. Make sure the PV's state is `Available`, otherwise please detach the PV first.
1. Remove the `spec.claimRef` field from the PV, otherwise the PV will be bound to the PVC
   and cannot be used by other PVCs.`
1. There are two ways to create the PVC:
   1. Create the PVC with `spec.volumeName` field set to the PV's name, thus the PVC will
      know which PV to use.
   1. Create the PVC with the same yaml file that was used to create the PV, then the PVC
      will generate the same name as the PV, and bind to the PV automatically.

### How to add imagePullSecrets to all Pods?

To add imagePullSecrets to all Pods, you can add it to all the service accounts used by
pods.

To patch the default service account, you have to add the following yaml file to the base
folder:

```yaml
# default-sa.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: default
```

and then add the following to the `kustomization.yaml` file to patch all service accounts:

```yaml
patches:
  - patch: |-
      kind: will-be-ignored
      metadata:
        name: will-be-ignored
      imagePullSecrets:
      - name: xxx
    target:
      kind: ServiceAccount
```
