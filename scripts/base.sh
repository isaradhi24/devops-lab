#!/usr/bin/env bash
set -e

# ------------------------------
# Update and install base packages
# ------------------------------
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y git curl vim net-tools ca-certificates gnupg lsb-release software-properties-common wget

# ------------------------------
# Disable swap (required for Kubernetes)
# ------------------------------
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# ------------------------------
# Enable IP forwarding
# ------------------------------
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-kubernetes-ipforward.conf
sudo sysctl --system

# ------------------------------
# Install containerd
# ------------------------------
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
sudo containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
sudo systemctl enable containerd

# ------------------------------
# Install Kubernetes binaries directly (stable version)
# ------------------------------
K8S_VERSION="v1.28.10"  # Stable version, change if needed

mkdir -p /tmp/k8s && cd /tmp/k8s

curl -LO https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubeadm
curl -LO https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubectl
curl -LO https://dl.k8s.io/release/${K8S_VERSION}/bin/linux/amd64/kubelet

chmod +x kubeadm kubectl kubelet
sudo mv kubeadm kubectl kubelet /usr/local/bin/

# ------------------------------
# Create systemd service for kubelet (manual install)
# ------------------------------
sudo tee /etc/systemd/system/kubelet.service > /dev/null <<EOF
[Unit]
Description=Kubernetes Kubelet
Documentation=https://kubernetes.io/docs/
After=network.target

[Service]
ExecStart=/usr/local/bin/kubelet
Restart=always
RestartSec=5
StartLimitInterval=0
# Allow kubelet to create and manage required directories
ExecStartPre=/bin/mkdir -p /var/lib/kubelet
ExecStartPre=/bin/mkdir -p /var/lib/kubelet/plugins
ExecStartPre=/bin/mkdir -p /var/lib/kubelet/pods
Environment="KUBELET_EXTRA_ARGS=--cgroup-driver=systemd"
# Important for kubelet to work
Slice=kubelet.slice
CPUAccounting=true
MemoryAccounting=true

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd, enable and start kubelet
sudo systemctl daemon-reload
sudo systemctl enable kubelet
sudo systemctl start kubelet

# ------------------------------
# Enable kubelet service
# ------------------------------
sudo systemctl enable kubelet
sudo systemctl start kubelet

# ------------------------------
# Verify Kubernetes binaries
# ------------------------------
kubeadm version || true
kubectl version --client --short || true
kubelet --version || true

# ------------------------------
# Done
# ------------------------------
echo "✅ Base system, containerd, and Kubernetes binaries installed successfully."