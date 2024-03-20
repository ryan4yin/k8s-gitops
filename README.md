# k8s-as-code

Repository for my personal kubernetes clusters.

## Prerequisites

All my Kubernetes Clusters are deployed via [ryan4yin/nix-config/hosts/k8s](https://github.com/ryan4yin/nix-config/tree/main/hosts/k8s).

```bash
nix shell nixpkgs#fluxcd
```

## Bootstrap

Steps to bootstrap a new cluster:

1. Add a new folder in `clusters/` with the name of the cluster.
1. Add the bootstrap configs into the new folder.
1. Run the bootstrap script(via `ssh-agent`) to bootstrap or update the cluster:
   ```bash
   flux bootstrap git \
   --components-extra image-reflector-controller,image-automation-controller \
   --url=ssh://git@github.com/ryan4yin/k8s-gitops \
   --branch=main \
   --path=clusters/k3s-prod-1
   ```
1. Add the printed public key to the git repository, as a deploy key with write access.

## Usage

Add your configs into those directories, fluxcd will take care of the rest:

```bash
› tree
.
├── apps             # app-specific configs
├── clusters         # cluster-wide configs
│   └── k3s-prod-1   # cluster name
├── infra            # cluster-wide infra files(monitoring, networking, certificates, etc.)
```

CLI usage:

```bash
# show stats
flux stats

# show stats for a specific resource, such as kustomization
flux get kustomization

# show k8s events (reconcile, build, deploy, etc)
flux events

# reconcile a specific git repo
flux reconcile source git flux-system

# get all other resources' status
flux get all

# show image automation status
flux get images all

# show more details
flux --help
```

## TODO

- [ ] Add longhorn, etc.
- [ ] Add alert-manager config for fluxcd itself.
- [ ] Web UI for monitoring fluxcd and cluster's status.

## FAQ

### 401: unauthorized - Helm charts fetched from an OCI Registry

This is a known issue, most likely because the URL path is miswritten, it needs to separate the prefix part of the OCI URL from the image name.

### unable to locate any tags in provided repository: oci://xxx

A known issue too, the v prefix in oci image tags is not supported by Helm nor Flux, see [flux2/issues/3766](https://github.com/fluxcd/flux2/issues/3766) for details.

To fix the issue, you have to rename the tag to remove the v prefix.

### Will Flux2 Overwrite My Existing Resources?

No, flux2 will refuse to deploy if there are existing resources with the same name in the cluster.
To get flux2 to overwrite the existing resources, you need to delete the existing resources first.

### Namespace stuck in `Terminating` status

> [Stop Messing with Kubernetes Finalizers](https://martinheinz.dev/blog/74)

> https://kubernetes.io/docs/concepts/overview/working-with-objects/finalizers/

> https://stackoverflow.com/questions/52369247/namespace-stucked-as-terminating-how-i-removed-it

Deleting objects in Kubernetes can be challenging. 
You may think you’ve deleted something, only to find it still persists. 

Especially when you delete a namespace with some CRDs or PVs, it may stuck in `Terminating` status and never be deleted.

For PV/PVC with `kubernetes.io/pv-protection` finalizer, you have to make sure the PV/PVC is not needed anymore, and then delete the finalizer manually.

For CRDs provided by operators, you have to **delete the CRs first**, and then delete the operators and namespace, otherwise the namespace will stuck in `Terminating` status!
This is because delete a CR will trigger the operator to delete the corresponding resources,
and if the operator is deleted before the CRs, the webhook will not work and the CRs will fail to be deleted, and the namespace will stuck in `Terminating` status.

So we have to add our CRs into `infra/configs` folder, and declare that
it's depends on `infra/controllers` in the `kustomization.yaml` file, so that Flux2 will delete the CRs first before the operators.

#### Special Cases - Kubevirt

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

#### Special Cases - What if my operator has already been deleted?

Here we use `kubevirt` as an example, the workflow is similar for other operators(such as longhorn).

Find what remains in the namespace:

```bash
› kubectl api-resources --verbs=list --namespaced -o name   | xargs -n 1 kubectl get --show-kind --ignore-not-found -n kubevirt

NAME                            AGE     PHASE
kubevirt.kubevirt.io/kubevirt   2d21h   Deployed
```

Since the operator has been deleted, we have to force delete the CRs, and remove cleanup the resources manually.

Try to patch the CRs to remove the finalizer, but it will not work:

```bash
› kubectl patch --type merge --patch '{"metadata":{"finalizers":null}}' -n kubevirt kubevirt/kubevirt 

Error from server (InternalError): Internal error occurred: failed calling webhook "kubevirt-validator.kubevirt.io": failed to call webhook: Post "https://kubevirt-operator-webhook.kubevirt.svc:443/kubevirt-validate-delete?timeout=10s": service "kubevirt-operator-webhook" not found
```

Remove kubevirt's `ValidatingWebhookConfiguration` and `MutatingWebhookConfiguration` manually to skip the webhook validation:

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
RES=$(kubectl api-resources --verbs=list --namespaced -o name   | xargs -n 1 kubectl get --show-kind --ignore-not-found -n monitoring | grep -v NAME | awk '{print $1}')
kubectl patch --type merge --patch '{"metadata":{"finalizers":null}}' -n monitoring $RES
```

Then the namespace will be deleted automatically.

## References

- [Kustomize Tutorial: Comprehensive Guide For Beginners](https://devopscube.com/kustomize-tutorial/): A comprehensive guide for beginners to understand and use Kustomize for Kubernetes deployments, but it do not cover all the features of Kustomize.
- [Kustomize Official Examples](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/README.md)


## LICENSE

[MIT](LICENSE)
