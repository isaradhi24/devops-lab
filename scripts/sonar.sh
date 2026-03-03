#!/usr/bin/env bash
set -e

sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker vagrant

docker run -d --name sonarqube \
  -p 9000:9000 \
  sonarqube:lts-community

echo "SonarQube: http://192.168.56.30:9000 (admin/admin)"
