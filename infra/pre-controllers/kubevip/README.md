# Kube-VIP

Kube-VIP is a highly available Kubernetes Load-Balancer and IP failover solution.

On K3s, it can be installed as a DaemonSet to provide a highly available Load-Balancer for K8s services and k3s's control plane.

> https://kube-vip.io/docs/installation/daemonset/

## Notes

For k3s, we have to add `--tls-san <your-domain-name-or-vip>` to the k3s server command line.
This is so that K3s generates an API server certificate with the kube-vip virtual IP or your domain name as a SAN.

Then you can modify your DNS to resolve the VIP to the K3s server node.


