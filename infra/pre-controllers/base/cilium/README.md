# Cilium - Pod network

To use cilium as the network plugin, you have to install it via helm first:

```bash
# To get all nodes ready, cilium(network plugin) has to be installed first.
helm repo add cilium https://helm.cilium.io/
helm search repo cilium/cilium -l | head
helm install cilium cilium/cilium --version 1.15.3 --namespace kube-system
```

And then you can deploy fluxcd and use it to manage cilium's configs.


## Known issues

### 1. Cilium has issues with KubeVirt on K3s

If you disable k3s's defalut network plugin `flannel` and use `cilium` instead,
you may encounter some issues with KubeVirt:

1. multus CNI plugin will failed to start.
1. kubevirt's virt-handler will complain about `failed to configure vmi network: setup failed, err: pod link (pod6b4853bd4f2) is missing`.

So do not use `cilium` as the network plugin on K3s if you want to use KubeVirt.

