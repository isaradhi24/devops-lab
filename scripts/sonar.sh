#!/bin/bash
set -e

echo "================================="
echo "Starting SonarQube installation..."
echo "================================="

# ------------------------------
# Install Java (required by SonarQube)
# ------------------------------
echo "Installing OpenJDK 17..."
sudo apt-get update
sudo apt-get install -y openjdk-17-jre unzip wget curl gnupg fontconfig

# Verify Java
java -version || true

# ------------------------------
# Add SonarQube GPG key & repository
# ------------------------------
echo "Adding SonarQube GPG key..."
curl -fsSL https://binaries.sonarsource.com/Distribution/sonarqube/sonar.gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/sonarqube-keyring.gpg

echo "Adding SonarQube APT repository..."
echo "deb [signed-by=/usr/share/keyrings/sonarqube-keyring.gpg] https://binaries.sonarsource.com/Distribution/sonarqube/deb stable main" \
  | sudo tee /etc/apt/sources.list.d/sonarqube.list > /dev/null

# ------------------------------
# Update package list
# ------------------------------
echo "Updating package list with SonarQube repository..."
sudo apt-get update

# ------------------------------
# Install SonarQube
# ------------------------------
echo "Installing SonarQube..."
sudo apt-get install -y sonarqube

# ------------------------------
# Enable and start SonarQube service
# ------------------------------
echo "Enabling and starting SonarQube service..."
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

# ------------------------------
# Post-install information
# ------------------------------
echo "================================="
echo "SonarQube installation completed."
echo "SonarQube should be running now."
echo "URL: http://192.168.56.30:9000"
echo "Default login: admin / admin"
echo "================================="

# ------------------------------
# Enable and start kubelet containerd jenkins sonarqube services
# ------------------------------
sudo systemctl enable kubelet containerd jenkins sonarqube
sudo systemctl start kubelet containerd jenkins sonarqube