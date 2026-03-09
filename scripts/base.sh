#!/usr/bin/env bash
set -e

# ------------------------------
# Base system update and packages
# ------------------------------
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y git curl vim net-tools ca-certificates gnupg lsb-release apt-transport-https software-properties-common

# ------------------------------
# Disable swap (required for Kubernetes)
# ------------------------------
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# ------------------------------
# Enable IP forwarding (required for Kubernetes networking)
# ------------------------------
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-kubernetes-ipforward.conf
sudo sysctl --system

# ------------------------------
# Install containerd (CRI runtime)
# ------------------------------
sudo apt-get install -y containerd

# Generate default containerd config
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Restart and enable containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# ------------------------------
# Configure Kubernetes apt repository (Ubuntu 22.04 / Jammy)
# ------------------------------
sudo mkdir -p /usr/share/keyrings
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg

# Use correct repo for Ubuntu 22.04
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-apt main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update and install Kubernetes components
sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service
sudo systemctl enable kubelet
sudo systemctl start kubelet

# ------------------------------
# Verify versions (ignore errors if binary is not fully ready yet)
# ------------------------------
kubectl version --client --short || true
kubeadm version || true
kubelet --version || true

# ------------------------------
# Done
# ------------------------------
echo "✅ Base system, containerd, and Kubernetes binaries installed successfully."