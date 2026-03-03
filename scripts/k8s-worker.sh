#!/usr/bin/env bash
set -e

bash /vagrant/scripts/k8s-common.sh

if [ -f /vagrant/scripts/kubeadm_join.sh ]; then
  sudo /vagrant/scripts/kubeadm_join.sh
else
  echo "Join script not found yet. Run 'vagrant provision k8s-worker1' again after master is ready."
fi
