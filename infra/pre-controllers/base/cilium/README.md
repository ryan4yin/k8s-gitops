# Cilium - Pod network

Cilium is the pod network on `k3s-test-1`; k3s runs with `--flannel-backend=none`. There
is no CNI until Cilium is installed, so **Flux cannot start on a fresh cluster** and the
first install must be done manually (Flux adopts it afterwards):

```bash
# from a host with a kubeconfig, after the nodes have flannel disabled
helm repo add cilium https://helm.cilium.io/
# keep these values in sync with infra/pre-controllers/base/cilium/helm-release.yaml
helm upgrade -i cilium cilium/cilium --version 1.20.2 --namespace kube-system \
  --set cni.exclusive=false --set socketLB.hostNamespaceOnly=true \
  --set ipv6.enabled=true --set enableIPv6Masquerade=true --set l7Proxy=false
```

And then you can deploy fluxcd and use it to manage cilium's configs.

## Istio compatibility

- `cni.exclusive=false` keeps the Istio CNI configuration alongside Cilium's CNI
  configuration.
- `socketLB.hostNamespaceOnly=true` prevents socket load balancing inside pods from
  bypassing Istio's traffic interception.

See the
[Cilium and Istio integration guide](https://docs.cilium.io/en/stable/network/servicemesh/istio/)
for these settings.
