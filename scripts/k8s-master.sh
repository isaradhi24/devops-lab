#!/usr/bin/env bash
set -euo pipefail

### --- Config -----------------------------------------------------------------

POD_CIDR="10.244.0.0/16"
API_ADVERTISE="192.168.56.10"          # matches your Vagrant private IP
NODE_NAME="k8s-master"                 # hostname from Vagrantfile
EXTRA_SANS="127.0.0.1,${API_ADVERTISE}"

KUBECONFIG_ADMIN="/etc/kubernetes/admin.conf"
FLANNEL_MANIFEST="https://raw.githubusercontent.com/flannel-io/flannel/v0.25.5/Documentation/kube-flannel.yml"

### --- Helpers ----------------------------------------------------------------

log() {
  echo "[$(date +'%H:%M:%S')] [k8s-master] $*"
}

is_cluster_healthy() {
  if [ ! -f "${KUBECONFIG_ADMIN}" ]; then
    return 1
  fi

  if ! kubectl --kubeconfig="${KUBECONFIG_ADMIN}" get --raw='/healthz' >/dev/null 2>&1; then
    return 1
  fi

  if ! kubectl --kubeconfig="${KUBECONFIG_ADMIN}" get node "${NODE_NAME}" >/dev/null 2>&1; then
    return 1
  fi

  local status
  status="$(kubectl --kubeconfig="${KUBECONFIG_ADMIN}" \
    get node "${NODE_NAME}" \
    -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || echo "")"

  [ "${status}" = "True" ]
}

ensure_cni_binaries() {
  log "Ensuring CNI binaries are present in /opt/cni/bin..."
  sudo mkdir -p /opt/cni/bin

  if [ -d /usr/lib/cni ]; then
    sudo cp -f /usr/lib/cni/* /opt/cni/bin/ || true
  fi
}

### --- Main -------------------------------------------------------------------

log "Starting Kubernetes master provisioning..."

if is_cluster_healthy; then
  log "Existing control plane is healthy; skipping reset and init."
  exit 0
fi

log "Cluster not healthy or not initialized; performing full reset..."

sudo kubeadm reset -f || true

log "Cleaning Kubernetes and CNI state..."
sudo systemctl stop kubelet || true
sudo systemctl stop containerd || true

sudo rm -rf \
  /etc/cni/net.d \
  /var/lib/cni \
  /var/lib/kubelet \
  /etc/kubernetes \
  /var/lib/etcd

sudo systemctl start containerd
sudo systemctl start kubelet

ensure_cni_binaries

log "Running kubeadm init..."
sudo kubeadm init \
  --pod-network-cidr="${POD_CIDR}" \
  --apiserver-advertise-address="${API_ADVERTISE}" \
  --apiserver-cert-extra-sans="${EXTRA_SANS}"

log "Configuring kubeconfig for vagrant user..."
mkdir -p "${HOME}/.kube"
sudo cp /etc/kubernetes/admin.conf "${HOME}/.kube/config"
sudo chown "$(id -u):$(id -g)" "${HOME}/.kube/config"

export KUBECONFIG="${HOME}/.kube/config"

log "Applying Flannel CNI..."
kubectl apply -f "${FLANNEL_MANIFEST}"

log "Waiting for node to become Ready..."
kubectl wait node "${NODE_NAME}" --for=condition=Ready --timeout=300s

log "Waiting for CoreDNS rollout..."
kubectl -n kube-system rollout status deploy/coredns --timeout=300s

log "Kubernetes master provisioning complete and healthy."
