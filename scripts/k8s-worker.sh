#!/usr/bin/env bash
set -e

echo "=========================================="
echo "Starting Kubernetes Worker Provisioning"
echo "=========================================="

###############################################
# 1️⃣ Common Kubernetes setup
###############################################
bash /vagrant/scripts/k8s-common.sh

###############################################
# 2️⃣ Reset cluster if already joined
###############################################
if [ -f /etc/kubernetes/kubelet.conf ]; then
  echo "Node already part of cluster. Resetting..."
  sudo kubeadm reset -f
  sudo rm -rf /etc/cni/net.d
  sudo ip link delete cni0 || true
  sudo ip link delete flannel.1 || true
fi

###############################################
# 3️⃣ Wait for master join script
###############################################
JOIN_SCRIPT="/vagrant/scripts/kubeadm_join.sh"

echo "Waiting for master join command..."
for i in {1..30}; do
  if [ -f "$JOIN_SCRIPT" ]; then
    echo "Join script found!"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 10
done

if [ ! -f "$JOIN_SCRIPT" ]; then
  echo "ERROR: Join script not found after waiting."
  echo "Run: vagrant provision k8s-master first"
  exit 1
fi

###############################################
# 4️⃣ Disable swap temporarily (required for kubeadm)
###############################################
if swapon --show | grep -q "/swapfile"; then
  echo "Disabling swap temporarily for kubeadm..."
  sudo swapoff -a
fi

###############################################
# 5️⃣ Join the cluster
###############################################
echo "Joining Kubernetes cluster..."
sudo bash "$JOIN_SCRIPT"

###############################################
# 6️⃣ Verify node joined successfully
###############################################
sleep 10
if systemctl is-active --quiet kubelet; then
  echo "Kubelet is running."
else
  echo "ERROR: kubelet not running!"
  exit 1
fi

###############################################
# 7️⃣ Re-enable swap for CI workloads
###############################################
if [ ! -f /swapfile ]; then
  echo "Creating 2G swapfile..."
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
fi

if ! swapon --show | grep -q "/swapfile"; then
  echo "Enabling swap..."
  sudo swapon /swapfile
fi

if ! grep -q "/swapfile" /etc/fstab; then
  echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
fi

echo "Swap configured successfully."

echo "Worker setup completed successfully."
echo "=========================================="