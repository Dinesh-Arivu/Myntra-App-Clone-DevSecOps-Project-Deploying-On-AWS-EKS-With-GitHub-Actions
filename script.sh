#!/bin/bash

set -e  # Stop script on any error
set -u  # Exit on unset variable
set -o pipefail  # Catch errors in pipelines

echo "=== Updating system and installing Java (temurin-17-jdk) ==="
sudo apt update -y
sudo touch /etc/apt/keyrings/adoptium.asc
sudo wget -O /etc/apt/keyrings/adoptium.asc https://packages.adoptium.net/artifactory/api/gpg/key/public
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | sudo tee /etc/apt/sources.list.d/adoptium.list
sudo apt update -y
sudo apt install temurin-17-jdk -y
/usr/bin/java --version

echo "=== Installing Docker ==="
sudo apt-get install docker.io -y
sudo systemctl start docker
sudo systemctl enable docker

# Add user to Docker group (assumes user is 'ubuntu' - replace if needed)
sudo usermod -aG docker ubuntu

# Reload group membership (may not take effect in the current shell)
newgrp docker || true

# Optional: allow docker socket for all users (security risk in production)
sudo chmod 666 /var/run/docker.sock

echo "=== Pulling and running SonarQube container ==="
# SonarQube requires at least 2GB RAM; can fail otherwise
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

echo "=== Install Docker Scout ==="
curl -sSfL https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh -s -- -b /usr/local/bin
docker-scout version

echo "=== Install kubectl ==="
sudo apt update
sudo apt install curl -y
curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

echo "=== Install Terraform ==="
sudo apt install wget -y
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform -y

echo "=== Install AWS CLI ==="
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install unzip -y
unzip awscliv2.zip
sudo ./aws/install

echo "=== Install Node.js 16 and npm ===" 
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/nodesource-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nodesource-archive-keyring.gpg] https://deb.nodesource.com/node_16.x focal main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt update
sudo apt install -y nodejs

echo "=== All installations completed successfully ==="
