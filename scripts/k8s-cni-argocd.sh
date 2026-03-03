#!/usr/bin/env bash
set -e

export KUBECONFIG=$HOME/.kube/config

echo "Waiting for Kubernetes API server to become ready (timeout: 300s)..."
SECONDS=0
while ! kubectl get --raw='/healthz' 2>/dev/null | grep -q 'ok'; do
  if [ $SECONDS -gt 300 ]; then
    echo "API server did not become ready within 5 minutes."
    exit 1
  fi
  echo "  - API not ready yet... waiting"
  sleep 5
done
echo "API server is healthy."

echo "Waiting for node to become Ready..."
SECONDS=0
while ! kubectl get nodes 2>/dev/null | grep -w "Ready"; do
  if [ $SECONDS -gt 300 ]; then
    echo "Node did not become Ready within 5 minutes."
    exit 1
  fi
  echo "  - Node not Ready yet... waiting"
  sleep 5
done
echo "Node is Ready."

echo "Applying Flannel CNI..."
kubectl apply -f https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml

echo "Waiting for Flannel pods..."
SECONDS=0
while ! kubectl -n kube-flannel get pods 2>/dev/null | grep -q "Running"; do
  if [ $SECONDS -gt 300 ]; then
    echo "Flannel did not become ready within 5 minutes."
    exit 1
  fi
  echo "  - Flannel not ready yet... waiting"
  sleep 5
done
echo "Flannel is Running."

echo "Creating ArgoCD namespace..."
kubectl create namespace argocd 2>/dev/null || true

echo "Applying ArgoCD manifests..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml --validate=false

echo "ArgoCD installation triggered."
