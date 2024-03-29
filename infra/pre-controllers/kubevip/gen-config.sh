curl -o rbac.yaml https://kube-vip.io/manifests/rbac.yaml

export VIP=192.168.5.187
# set vip on the main interface, we use openvswitch, so we set it on ovs's bridge
export INTERFACE=ovsbr1

# https://github.com/kube-vip/kube-vip/releases
export KVVERSION=v0.7.2

# generate daemonset.yaml, using ARP mode
docker run --network host --rm ghcr.io/kube-vip/kube-vip:$KVVERSION \
  manifest daemonset \
  --interface $INTERFACE \
  --address $VIP \
  --inCluster \
  --taint \
  --controlplane \
  --services \
  --arp \
  --leaderElection | tee daemonset.yaml

