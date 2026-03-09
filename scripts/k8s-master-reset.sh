#!/bin/bash
set -e

# Only reset if cluster exists
if [ -f /etc/kubernetes/admin.conf ]; then
  echo "Existing Kubernetes cluster detected. Resetting..."
  sudo kubeadm reset -f
  sudo rm -rf /etc/cni/net.d /var/lib/cni /var/lib/kubelet /etc/kubernetes/manifests
  sudo ip link delete cni0 || true
  sudo ip link delete flannel.1 || true
  rm -rf $HOME/.kube
  sudo rm -f /etc/kubernetes/admin.conf
else
  echo "No existing Kubernetes cluster. Skipping reset."
fi

# Init Kubernetes master only if not initialized
if [ ! -f /etc/kubernetes/admin.conf ]; then
  echo "Initializing Kubernetes master..."
  sudo kubeadm init \
    --apiserver-cert-extra-sans=10.0.2.15,192.168.56.10,10.96.0.1,127.0.0.1 \
    --pod-network-cidr=10.244.0.0/16 \
    --kubernetes-version stable-1.35

  # Configure kubeconfig for vagrant user
  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config
  chmod 600 $HOME/.kube/config

  # Deploy Flannel CNI
  kubectl apply -f /vagrant/manifests/kube-flannel.yml

  # Wait for Flannel pods
  echo "Waiting for Flannel to be ready..."
  kubectl -n kube-flannel wait --for=condition=Ready pod -l app=flannel --timeout=180s

  # Show node status
  kubectl get nodes -o wide

  # Master generates join script for workers
  kubeadm token create --print-join-command > /vagrant/scripts/kubeadm_join.sh
  chmod +x /vagrant/scripts/kubeadm_join.sh
else
  echo "Kubernetes master already initialized. Skipping init."
fi