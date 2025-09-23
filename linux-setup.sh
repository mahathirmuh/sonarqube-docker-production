#!/bin/bash
# Linux setup script for SonarQube Docker

echo "Setting up SonarQube for Linux environment..."

# Check if running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Set kernel parameters for SonarQube
echo "Setting kernel parameters..."
echo "vm.max_map_count=262144" >> /etc/sysctl.conf
echo "fs.file-max=65536" >> /etc/sysctl.conf
sysctl -p

# Set user limits
echo "Setting user limits..."
echo "* soft nofile 65536" >> /etc/security/limits.conf
echo "* hard nofile 65536" >> /etc/security/limits.conf
echo "* soft nproc 4096" >> /etc/security/limits.conf
echo "* hard nproc 4096" >> /etc/security/limits.conf

# Create .env file from template if it doesn't exist
if [ ! -f .env ] && [ -f .env.template ]; then
    echo "Creating .env file from template..."
    cp .env.template .env
    echo "Please edit .env file with your specific configurations"
fi

echo "\nSetup complete! You can now run SonarQube using:\n"
echo "docker-compose up -d"
echo "\nAccess SonarQube at: http://localhost:9010"
echo "Default credentials: admin / admin"