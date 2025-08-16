#!/bin/bash

set -e  # Stop script on any error
set -u  # Exit on unset variable
set -o pipefail  # Catch errors in pipelines

echo "=== Updating system and installing Java (OpenJDK 17) ==="
sudo apt update -y
sudo apt install openjdk-17-jdk -y
java -version

echo "=== Installing Jenkins ==="
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins
sudo systemctl status jenkins --no-pager

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

echo "=== Installing Trivy ==="
sudo apt-get install wget apt-transport-https gnupg lsb-release -y
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt-get update
sudo apt-get install trivy -y

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

echo "=== All installations completed successfully ==="