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

Problem 1:

```
kubectl describe ns cert-managear

  aNamespaceDeletionDiscoveryFailure            True    Tue, 19 Mar 2024 01:12:15 +0800  DiscoveryFailed         Discovery failed for some groups, 2 failing: unable t
o retrieve the complete list of server APIs: subresources.kubevirt.io/v1: stale GroupVersion discovery: subresources.kubevirt.io/v1, subresources.kubevirt.io/v1alpha
3: stale GroupVersion discovery: subresources.kubevirt.io/v1alpha3
```

Seems related to <https://github.com/kubevirt/kubevirt/issues/9725>

Problem 2:

```
kubectl describe ns monitoring

...

  NamespaceContentRemaining                    True    Tue, 19 Mar 2024 01:12:11 +0800  SomeResourcesRemain   Some resources are remaining: configmaps. has 3 resourc
e instances, deployments.apps has 3 resource instances, persistentvolumeclaims. has 1 resource instances, secrets. has 4 resource instances, serviceaccounts. has 4 r
esource instances, services. has 4 resource instances, statefulsets.apps has 1 resource instances, vmagents.operator.victoriametrics.com has 1 resource instances, vm
alertmanagers.operator.victoriametrics.com has 1 resource instances, vmalerts.operator.victoriametrics.com has 1 resource instances, vmsingles.operator.victoriametri
cs.com has 1 resource instances
  NamespaceFinalizersRemaining                 True    Tue, 19 Mar 2024 01:12:11 +0800  SomeFinalizersRemain  Some content in the namespace has finalizers remaining:
 apps.victoriametrics.com/finalizer in 24 resource instances
```

So it seems I have to deleete all the statefulsets, pv, crds, configmaps and secrets manually,
and then Kubernetes will confirm all the finalizers are finished and delete the namespace completely.


## References

- [Kustomize Tutorial: Comprehensive Guide For Beginners](https://devopscube.com/kustomize-tutorial/): A comprehensive guide for beginners to understand and use Kustomize for Kubernetes deployments, but it do not cover all the features of Kustomize.
- [Kustomize Official Examples](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/README.md)


## LICENSE

[MIT](LICENSE)
