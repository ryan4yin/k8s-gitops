# ========================================
# Install KubeVirt
# https://github.com/kubevirt/kubevirt/tree/main
# ========================================

export RELEASE=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
echo "The latest kubevirt's version is $RELEASE"

curl -Lo kubevirt-operator-${RELEASE}.yaml https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-operator.yaml
# curl -Lo kubevirt-cr-${RELEASE}.yaml https://github.com/kubevirt/kubevirt/releases/download/${RELEASE}/kubevirt-cr.yaml

# ========================================
# Install CDI(Containerized Data Importer)
# https://github.com/kubevirt/containerized-data-importer
# ========================================

export CDI_VERSION=$(curl -s https://api.github.com/repos/kubevirt/containerized-data-importer/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
echo "The latest CDI(Containerized Data Importer)'s version is $CDI_VERSION"

curl -Lo cdi-operator-${CDI_VERSION}.yaml https://github.com/kubevirt/containerized-data-importer/releases/download/$CDI_VERSION/cdi-operator.yaml
curl -Lo cdi-cr-${CDI_VERSION}.yaml https://github.com/kubevirt/containerized-data-importer/releases/download/$CDI_VERSION/cdi-cr.yaml

# CNAO was removed. Multus (thin) + reference CNI plugins are deployed by Flux
# (infra/pre-controllers/base/multus) and the VM secondary network uses the
# `bridge` CNI plugin on the Linux bridge br0.
