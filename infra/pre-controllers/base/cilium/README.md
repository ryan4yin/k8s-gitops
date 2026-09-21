# Cilium - Pod network

Cilium is the pod network on `kubevirt-lab-1` (and `k3s-test-1`); k3s runs with
`--flannel-backend=none`. There is no CNI until Cilium is installed, so **Flux cannot
start on a fresh cluster** and the first install must be done manually (Flux adopts it
afterwards):

```bash
# from a host with a kubeconfig, after the nodes have flannel disabled
helm repo add cilium https://helm.cilium.io/
# keep these values in sync with infra/pre-controllers/base/cilium/helm-release.yaml
helm upgrade -i cilium cilium/cilium --version 1.19.8 --namespace kube-system \
  --set cni.exclusive=false --set socketLB.hostNamespaceOnly=true \
  --set ipv6.enabled=true --set enableIPv6Masquerade=true --set l7Proxy=false
```

And then you can deploy fluxcd and use it to manage cilium's configs.

## KubeVirt notes

- `cni.exclusive=false` is required when Multus is used. The default (`true`) makes Cilium
  rename every other CNI config (including Multus's `00-multus.conf`) to `*.cilium_bak`,
  so secondary networks never come up and virt-handler reports
  `failed to configure vmi network: setup failed, err: pod link (pod6b4853bd4f2) is missing`.
- Use Cilium `>= 1.19.5`: earlier 1.17-1.19 releases stomp the MTU of multus-attached
  interfaces (https://github.com/cilium/cilium/issues/37824).
- Keep the datapath as `veth` (chart default). If netkit is enabled, use `netkit-l2`, not
  `netkit` (L3): the L3 mode gives the pod NIC an all-zero MAC and breaks KubeVirt
  (https://github.com/cilium/cilium/issues/37265).
