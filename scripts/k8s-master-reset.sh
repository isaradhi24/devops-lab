#!/bin/bash
set -e

# Reset Kubernetes if it exists
sudo kubeadm reset -f
sudo rm -rf /etc/cni/net.d /var/lib/cni /var/lib/kubelet /etc/kubernetes/manifests
sudo ip link delete cni0 || true
sudo ip link delete flannel.1 || true

# Clean kube configs
rm -rf $HOME/.kube
sudo rm -f /etc/kubernetes/admin.conf

# Init Kubernetes master
sudo kubeadm init \
  --apiserver-cert-extra-sans=10.0.2.15,192.168.56.10,10.96.0.1,127.0.0.1 \
  --pod-network-cidr=10.244.0.0/16 \
  --kubernetes-version stable-1.30

# Configure kubeconfig for vagrant user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
chmod 600 $HOME/.kube/config

# Deploy Flannel CNI
# kubectl apply -f ~/devops-lab/manifests/kube-flannel.yml
kubectl apply -f /vagrant/manifests/kube-flannel.yml

# Wait for Flannel pods
echo "Waiting for Flannel to be ready..."
kubectl -n kube-flannel wait --for=condition=Ready pod -l app=flannel --timeout=120s

# Show node status
kubectl get nodes -o wide

# Master Generates Join Script
kubeadm token create --print-join-command > /vagrant/scripts/kubeadm_join.sh
chmod +x /vagrant/scripts/kubeadm_join.sh