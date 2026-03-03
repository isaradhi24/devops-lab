#!/usr/bin/env bash
set -e

bash /vagrant/scripts/k8s-common.sh

POD_CIDR="10.244.0.0/16"
sudo kubeadm init --pod-network-cidr=${POD_CIDR}

mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Save join command for workers
kubeadm token create --print-join-command | sudo tee /vagrant/scripts/kubeadm_join.sh
sudo chmod +x /vagrant/scripts/kubeadm_join.sh
