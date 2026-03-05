#!/usr/bin/env bash
set -e

# Replace with the latest token & hash from your master
KUBEADM_JOIN_CMD="kubeadm join 192.168.56.10:6443 --token 8kfzd7.t93bjo2iu1dm492n \
--discovery-token-ca-cert-hash sha256:73f328cc8bf9de502c2e48b1f93a734cec58b5c3953d7ef9488b1605503bf912"

echo "Executing: $KUBEADM_JOIN_CMD"
sudo $KUBEADM_JOIN_CMD