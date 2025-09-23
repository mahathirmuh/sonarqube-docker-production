#!/bin/bash
# Script to help migrate SonarQube Docker setup from Windows to Linux

echo "Starting Windows to Linux migration for SonarQube Docker..."

# Fix line endings in all text files
echo "Fixing line endings in configuration files..."
find . -type f -name "*.yml" -o -name "*.env" -o -name "*.md" -o -name "*.sh" | xargs -I{} sed -i 's/\r$//' {}

# Make shell scripts executable
echo "Making shell scripts executable..."
chmod +x *.sh

# Create .env file if it doesn't exist
if [ ! -f .env ] && [ -f .env.template ]; then
    echo "Creating .env file from template..."
    cp .env.template .env
fi

# Check Docker and Docker Compose installation
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Please install Docker first."
    echo "Visit https://docs.docker.com/engine/install/ for installation instructions."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo "Docker Compose is not installed. Please install Docker Compose first."
    echo "Visit https://docs.docker.com/compose/install/ for installation instructions."
    exit 1
fi

# Check if user is in docker group
if ! groups | grep -q docker; then
    echo "WARNING: Current user is not in the docker group."
    echo "You may need to run docker commands with sudo or add your user to the docker group:"
    echo "sudo usermod -aG docker $USER"
    echo "(You'll need to log out and back in for this to take effect)"
fi

echo "\nMigration preparation complete!"
echo "\nNext steps:"
echo "1. Run the Linux setup script: sudo ./linux-setup.sh"
echo "2. Start SonarQube: docker-compose up -d"
echo "3. Access SonarQube at: http://localhost:9010"