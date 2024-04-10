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
flux get ks

# show k8s events (reconcile, build, deploy, etc)
flux events

# reconcile a specific git repo
flux reconcile source git flux-system

# get all other resources' status
flux get all -A

# show image automation status
flux get images all -A
# reconcile a specific image automation
flux reconcile image update <image-automation-name>

# retry a failed kustomization, such as infra-controllers
flux reconcile ks infra-controllers

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

### Will Flux2 Revert My Changes If I Manually Change The Resources via `kubectl`?

> https://fluxcd.io/flux/components/kustomize/kustomizations/#controlling-the-apply-behavior-of-resources

Yes, flux2 will revert your changes if you manually change the resources via `kubectl`.

You can control this behavior by add `kustomize.toolkit.fluxcd.io/ssa: Merge` to the resource's annotation,
to prevent flux2 from reverting the changes on the filed that is not defined in Git repository.
This is useful when you want to change `spec.replicas` of some CRDs manually.


## References

- [Kustomize Tutorial: Comprehensive Guide For Beginners](https://devopscube.com/kustomize-tutorial/): A comprehensive guide for beginners to understand and use Kustomize for Kubernetes deployments, but it do not cover all the features of Kustomize.
- [Kustomize Official Examples](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/README.md)
- [Kustomization API - FluxCD](https://fluxcd.io/flux/components/kustomize/kustomizations/)

## LICENSE

[MIT](LICENSE)
