#!/usr/bin/env bash
set -e

sudo apt-get update -y

# Install dependencies
sudo apt-get install -y openjdk-17-jdk curl gnupg2 ca-certificates

# Jenkins repo key
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
sudo tee /usr/share/keyrings/jenkins-keyring.asc >/dev/null

# Jenkins repo
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list

sudo apt-get update -y
sudo apt-get install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins

# Maven
sudo apt-get install -y maven

# Docker
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Permissions
sudo usermod -aG docker jenkins
sudo usermod -aG docker vagrant

sudo systemctl restart jenkins

echo "================================="
echo "Jenkins URL:"
echo "http://192.168.56.20:8080"
echo "================================="

echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true