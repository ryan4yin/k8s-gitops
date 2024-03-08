# k8s-as-code

Repository for my personal kubernetes clusters.

## Prerequisites

```bash
nix shell nixpkgs#fluxcd nixpkgs#nushell
```

## Bootstrap

Steps to bootstrap a new cluster:

1. Add a new folder in `clusters/` with the name of the cluster.
1. Add the bootstrap configs into the new folder.
1. Run the bootstrap script(via `ssh-agent`):
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
├── mock             # mock files for testing
└── scripts          # useful scripts
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

- [ ] Add victoriametrics, grafana, certificates, longhorn, kubevirt, etc.
   - Old config: [ryan4yin/nix-config/pulumi](https://github.com/ryan4yin/nix-config/tree/b7845ef85ede902691fae8fdd21d6d2e8e1516f4/pulumi)
- [ ] Add alert-manager config for fluxcd itself.
- [ ] Web UI for monitoring fluxcd and cluster's status.


## LICENSE

[MIT](LICENSE)
