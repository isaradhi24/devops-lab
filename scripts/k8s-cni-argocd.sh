#!/usr/bin/env bash
set -e

export KUBECONFIG=$HOME/.kube/config

# Flannel CNI
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

# Wait a bit for nodes to be Ready
sleep 30

# ArgoCD
kubectl create namespace argocd 2>/dev/null || true
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Expose ArgoCD via NodePort
kubectl -n argocd patch svc argocd-server \
  -p '{"spec": {"type": "NodePort"}}'

echo "ArgoCD installed. Get NodePort with: kubectl -n argocd get svc argocd-server"
