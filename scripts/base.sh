#!/usr/bin/env bash
set -e

sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install -y git curl vim net-tools ca-certificates gnupg lsb-release

# Disable swap for K8s compatibility (safe for all nodes in lab)
sudo swapoff -a
sudo sed -i '/ swap / s/^/#/' /etc/fstab

# Enable IP forwarding (required for Kubernetes)
echo "net.ipv4.ip_forward = 1" | sudo tee /etc/sysctl.d/99-kubernetes-ipforward.conf
sudo sysctl -p /etc/sysctl.d/99-kubernetes-ipforward.conf
