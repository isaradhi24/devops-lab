#!/usr/bin/env bash
set -e

###############################################
# Detect node role based on hostname
###############################################
HOSTNAME=$(hostname)

if [[ "$HOSTNAME" == *"master"* ]]; then
  NODE_ROLE="master"
else
  NODE_ROLE="worker"
fi

echo "Detected node role: $NODE_ROLE"

###############################################
# Install and configure containerd
###############################################
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd

if [ ! -f /etc/containerd/config.toml ]; then
  containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
fi

sudo systemctl restart containerd
sudo systemctl enable containerd

###############################################
# Install Kubernetes components
###############################################
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key \
  | sudo gpg --batch --yes --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] \
https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" \
  | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

###############################################
# Kernel networking settings (all nodes)
###############################################
sudo tee /etc/sysctl.d/k8s.conf >/dev/null <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sudo modprobe br_netfilter
sudo sysctl --system

###############################################
# Swap rules based on node role
###############################################

if [[ "$NODE_ROLE" == "master" ]]; then
  echo "Configuring master node: disabling swap."

  # Disable swap immediately
  sudo swapoff -a

  # Remove swap entries from fstab
  sudo sed -i '/swap/d' /etc/fstab

else
  echo "Configuring worker node: enabling swap for CI workloads."

  # Create swapfile only if missing
  if [ ! -f /swapfile ]; then
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
  fi

  # Enable swap if not active
  if ! swapon --show | grep -q "/swapfile"; then
    sudo swapon /swapfile
  fi

  # Add to fstab if missing
  if ! grep -q "/swapfile" /etc/fstab; then
    echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
  fi

  # Allow kubelet to run with swap enabled (after kubeadm join)
  if [ -f /var/lib/kubelet/config.yaml ]; then
    sudo sed -i 's/^failSwapOn:.*/failSwapOn: false/' /var/lib/kubelet/config.yaml
    sudo systemctl restart kubelet
  else
    echo "Kubelet config not found yet; will patch after kubeadm join."
  fi
fi

echo "k8s-common.sh completed for node role: $NODE_ROLE"
