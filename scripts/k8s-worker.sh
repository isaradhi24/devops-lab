#!/usr/bin/env bash
set -e

# Common Kubernetes setup
bash /vagrant/scripts/k8s-common.sh

# Join the cluster if join script exists
if [ -f /vagrant/scripts/kubeadm_join.sh ]; then
  sudo /vagrant/scripts/kubeadm_join.sh
else
  echo "Join script not found yet. Run 'vagrant provision k8s-worker1' again after master is ready."
fi

###############################################
# Enable swap safely for Jenkins-heavy workloads
###############################################

# Create swapfile only if it doesn't exist
if [ ! -f /swapfile ]; then
  echo "Creating 2G swapfile..."
  sudo fallocate -l 2G /swapfile
  sudo chmod 600 /swapfile
  sudo mkswap /swapfile
fi

# Enable swap if not already active
if ! swapon --show | grep -q "/swapfile"; then
  echo "Enabling swap..."
  sudo swapon /swapfile
fi

# Add to