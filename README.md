# k8s-as-code

Repository for my personal kubernetes clusters.

## Prerequisites

All my Kubernetes Clusters are deployed via
[ryan4yin/nix-config/hosts/k8s](https://github.com/ryan4yin/nix-config/tree/main/hosts/k8s).

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

> NOTE: kustomization, helmrelease and other resources are defined as k8s's CRDs, so you
> can use `kubectl get ks` or `k9s` to check the status of the resources too. use
> `flux get all -A` to get all resources' status is not the only way.

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

# suspend and resume a kustomization's sync
flux suspend ks vms
flux resume ks vms
```

## Secrets Management

> https://fluxcd.io/flux/guides/mozilla-sops/#encrypting-secrets-using-age

We use sops & age to manage secrets, so prerequisites:

```bash
nix shell nixpkgs#sops nixpkgs#age
```

### 1. Generate & add the age key to the cluster

> Generally one age key for one git repository is enough, so you need to generate the age
> key only once.

Generate a new age key first, add the age key into the cluster:

```bash
# generate a new age key
age-keygen -o k8s-gitops.agekey

# add the age key to the cluster
cat k8s-gitops.agekey |
kubectl create secret generic sops-age \
--namespace=flux-system \
--from-file=age.agekey=/dev/stdin
```

> NOTE: You may want to backup the age key in a secure place, as it's the only way to
> decrypt the secrets.

After that, you need to reference the age key in the kustomization config, e.g:

```yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: test
  namespace: flux-system
spec:
  sourceRef:
    kind: GitRepository
    name: flux-system
  path: ./infra/xxx
  # Add the following decryption config
  # https://fluxcd.io/flux/components/kustomize/kustomizations/#decryption
  decryption:
    provider: sops
    # reference the secret we created before
    secretRef:
      name: sops-age
```

Now, you can encrypt the secrets in the yaml files located in the `infra/xxx` directory,
and fluxcd will decrypt them automatically.

### 2. Encrypt secrets

> https://github.com/getsops/sops?tab=readme-ov-file#49encrypting-only-parts-of-a-file

To encrypt specific values in a yaml file using age's putlic key:

> NOTE: private keyfile is not needed here, it's only used for decryption in cluster.

```bash
# This is the age recipient public key, it's printed when you generate the age key
export AGE_RECIPIENT=xxxxx

# Encrypting only specific values in a yaml file
sops --encrypt --age=${AGE_RECIPIENT} \
  --encrypted-regex '^(data|stringData)$' --in-place /path/to/secrets.yaml

# Decrypting the encrypted values
sops --decrypt /path/to/secrets.yaml
```

Examples:

- TODO


### 3. Decrypt secrets

> https://github.com/getsops/sops?tab=readme-ov-file#22encrypting-using-age

Generally, you won't need to decrypt the secrets localy. To decrypt the secrets locally,
you can just replace the encrypted values with the plaintext values, and then encrypt them
again.

If you really need to decrypt the secrets locally, you can use the following command:

```bash
# Specify the private key file path
export SOPS_AGE_KEY_FILE=./k8s-gitops.agekey

# Decrypting the encrypted values
sops --decrypt /path/to/secrets.yaml
```

## TODO

- [ ] Add alert-manager config for fluxcd itself.
- [ ] Web UI for monitoring fluxcd and cluster's status.

## FAQ

See [FAQ](./FAQ.md).

## Cluster Security & Stability

To prevent damage to the cluster, we have to follow some rules:

1. **Do not use `kubectl apply` to apply changes to the cluster.** FluxCD will take care
   of the changes, and it will revert the changes if you apply them manually.
1. **Do not allow push to the `main` branch directly(except flux itself, or more
   accurately, flux's deploy key).** All changes should be made via PRs, and the PRs
   should be reviewed by at least one person.
   - NOTE: if you're using gitlab, the creator of the deploy key will gains the same
     access as the deploy key! So, **please create the deploy key with a separate
     account**.
1. **Do not enable flux's `prune` on critical resources, such as namespaces.** Prune will
   delete the resources that are not defined in the Git repository, which may cause damage
   to the cluster.
1. **Deploy resources that contains finalizers carefully.** Deleting resources with
   finalizers may cause the namespace stuck in `Terminating` status.
1. **Use `dependsOn` in `kustomization.yaml` to control the order of deployment and
   deletion.**
   1. For CRDs provided by operators, you have to delete the CRs first, and then delete
      the operators and namespace, otherwise the namespace will stuck in `Terminating`
      status.
   1. For PV/PVC with `kubernetes.io/pv-protection` finalizer, you have to make sure the
      PV/PVC is not needed anymore, and then delete the finalizer manually.
   1. For operators that adds its admission webhook to the CRs, you have to delete ther CR
      & admission webhook first, and then delete the operator and namespace. Otherwise,
      the CRs will fail to be deleted, and the namespace will stuck in `Terminating`
      status.
1. CI for PRs:
   [fluxcd/flux2-kustomize-helm-example/workflows](https://github.com/fluxcd/flux2-kustomize-helm-example/tree/main/.github/workflows)
1. Be especially careful when using flux to deploy **network plugins**, as network
   failures may prevent flux from accessing the git repositories or pulling the helm
   charts.
1. For the corporate environment, consider spliting gitops repositories & k8s clusters by
   categories. Use multiple git repos & k8s clusters may increase the management overhead,
   but it can also reduce the damage caused by accidents.

## References

- Flux Official Example:
  [fluxcd/flux2-kustomize-helm-example](https://github.com/fluxcd/flux2-kustomize-helm-example)
- [Kustomize Tutorial: Comprehensive Guide For Beginners](https://devopscube.com/kustomize-tutorial/):
  A comprehensive guide for beginners to understand and use Kustomize for Kubernetes
  deployments, but it do not cover all the features of Kustomize.
- [Kustomize Official Examples](https://github.com/kubernetes-sigs/kustomize/blob/master/examples/README.md)
- [Kustomize Official Docs](https://kubectl.docs.kubernetes.io/references/kustomize/)
- [JSON Patch - Docs](https://jsonpatch.com/)
- [Kustomization API - FluxCD](https://fluxcd.io/flux/components/kustomize/kustomizations/)

## LICENSE

[MIT](LICENSE)
