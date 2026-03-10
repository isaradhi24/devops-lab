#!/bin/bash
set -e

echo "Installing dependencies..."
sudo apt-get update
sudo apt-get install -y curl gnupg fontconfig openjdk-17-jre apt-transport-https ca-certificates

# ------------------------------
echo "Adding Jenkins GPG key..."
# ------------------------------
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
 | sudo gpg --dearmor -o /usr/share/keyrings/jenkins-keyring.gpg

# ------------------------------
echo "Adding Jenkins repository..."
# ------------------------------
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
 | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# ------------------------------
echo "Updating package list with key verification..."
# ------------------------------
sudo apt-get update --allow-releaseinfo-change

# Retry loop for stubborn NO_PUBKEY errors
for i in {1..3}; do
    if sudo apt-get update; then
        break
    else
        echo "Retrying apt-get update ($i)..."
        sleep 5
    fi
done

# ------------------------------
echo "Installing Jenkins..."
# ------------------------------
sudo apt-get install -y jenkins

# ------------------------------
echo "Enabling and starting Jenkins..."
# ------------------------------
sudo systemctl enable jenkins
sudo systemctl start jenkins

echo "================================="
echo "Jenkins installation completed."
echo "Jenkins installed successfully"
echo "Jenkins URL: http://192.168.56.20:8080"
echo "================================="

# ------------------------------
# Enable and start kubelet containerd jenkins sonarqube services
# ------------------------------
sudo systemctl enable kubelet containerd jenkins sonarqube
sudo systemctl start kubelet containerd jenkins sonarqube

echo "Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || true