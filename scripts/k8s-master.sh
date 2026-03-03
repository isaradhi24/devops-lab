#!/usr/bin/env bash
set -e

###############################################
# Detect if master is already initialized
###############################################
if [ -f /etc/kubernetes/admin.conf ]; then
  echo "Kubernetes control plane already initialized. Skipping kubeadm init."

  # Ensure vagrant kubeconfig exists (idempotent)
  sudo mkdir -p /home/vagrant/.kube
  sudo cp -f /etc/kubernetes/admin.conf /home/vagrant/.kube/config
  sudo chown vagrant:vagrant /home/vagrant/.kube/config

  # Ensure join script exists (regenerate if missing)
  if [ ! -f /vagrant/scripts/kubeadm_join.sh ]; then
    echo "Regenerating worker join script..."
    kubeadm token create --print-join-command | sudo tee /vagrant/scripts/kubeadm_join.sh
    sudo chmod +x /vagrant/scripts/kubeadm_join.sh
  fi

  exit 0
fi

###############################################
# Run common setup (containerd, kubelet, sysctl)
###############################################
bash /vagrant/scripts/k8s-common.sh

###############################################
# Initialize Kubernetes control plane
###############################################
POD_CIDR="10.244.0.0/16"

echo "Running kubeadm init..."
sudo kubeadm init --pod-network-cidr=${POD_CIDR}

###############################################
# Configure kubectl for vagrant user
###############################################
sudo mkdir -p /home/vagrant/.kube
sudo cp /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown vagrant:vagrant /home/vagrant/.kube/config

###############################################
# Generate join command for workers
###############################################
echo "Generating worker join script..."
kubeadm token create --print-join-command | sudo tee /vagrant/scripts/kubeadm_join.sh
sudo chmod +x /vagrant/scripts/kubeadm_join.sh

echo "Master node initialization complete."
