# k8s-as-code

Repository for my personal kubernetes clusters.

## Prerequisites

All my Kubernetes Clusters are deployed via [ryan4yin/nix-config/hosts/k8s](https://github.com/ryan4yin/nix-config/tree/main/hosts/k8s).

```bash
nix shell nixpkgs#fluxcd
```

My personal container images:

- Dockerfile & CI: <https://github.com/ryan4yin/containers>
- Docker Hub: <https://hub.docker.com/r/ryan4yin>

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
   --path=clusters/k3s-test-1
   ```
1. Add the printed public key to the git repository, as a deploy key with write access.

## Usage

Add your configs into those directories, fluxcd will take care of the rest:

```bash
› tree
.
├── apps             # app-specific configs
├── clusters         # cluster-wide configs
│   └── k3s-test-1   # cluster name
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

See [FAQ](./FAQ.md).

## Cluster Security & Stability

To prevent damage to the cluster, we have to follow some rules:

1. **Do not use `kubectl apply` to apply changes to the cluster.**
   FluxCD will take care of the changes, and it will revert the changes if you apply them manually.
1. **Do not allow push to the `main` branch directly(except flux itself, or more accurately,, flux's deploy key).**
   All changes should be made via PRs, and the PRs should be reviewed by at least one person.
1. **Do not enable flux's `prune` on critical resources, such as namespaces.**
   Prune will delete the resources that are not defined in the Git repository, which may cause damage to the cluster.
1. **Deploy resources that contains finalizers carefully.**
   Deleting resources with finalizers may cause the namespace stuck in `Terminating` status.
1. **Use `dependsOn` in `kustomization.yaml` to control the order of deployment and deletion.**
   1. For CRDs provided by operators, you have to delete the CRs first, and then delete the operators and namespace, otherwise the namespace will stuck in `Terminating` status.
   1. For PV/PVC with `kubernetes.io/pv-protection` finalizer, you have to make sure the PV/PVC is not needed anymore, and then delete the finalizer manually.
   1. For operators that adds its admission webhook to the CRs, you have to delete ther CR & admission webhook first, and then delete the operator and namespace.
      Otherwise, the CRs will fail to be deleted, and the namespace will stuck in `Terminating` status.
1. CI for PRs: [fluxcd/flux2-kustomize-helm-example/workflows](https://github.com/fluxcd/flux2-kustomize-helm-example/tree/main/.github/workflows)

## References

- Flux Official Example: [fluxcd/flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example)
- [Kustomize Tutorial: Comprehensive Guide For Beginners](https://devopscube.com/kustomize-tutorial/): A comprehensive guide for beginners to understand and use Kustomize for Kubernetes deployments, but it do not cover all the features of Kustomize.
- [Kustomize Official Examples](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/README.md)
- [JSON Patch - Docs](https://jsonpatch.com/)
- [Kustomization API - FluxCD](https://fluxcd.io/flux/components/kustomize/kustomizations/)

## LICENSE

[MIT](LICENSE)
