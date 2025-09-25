#!/bin/bash
# Docker Security Hardening Script for SonarQube on Linux
# This script applies Docker security best practices to your SonarQube setup

# Ensure we're running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

# Display banner
echo "======================================================="
echo "      Docker Security Hardening for SonarQube          "
echo "======================================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
else
    echo "✓ Docker is running"
fi

# Function to enable Docker Content Trust
enable_docker_content_trust() {
    echo "Enabling Docker Content Trust..."
    export DOCKER_CONTENT_TRUST=1
    echo "export DOCKER_CONTENT_TRUST=1" >> ~/.bashrc
    echo "export DOCKER_CONTENT_TRUST=1" >> /etc/environment
    echo "✓ Docker Content Trust enabled"
}

# Function to run security scan with Trivy
invoke_trivy_scan() {
    local image_name=$1
    
    echo "Running security scan on $image_name..."
    
    # Check if Trivy is available
    if ! docker run --rm aquasec/trivy --version > /dev/null 2>&1; then
        echo "Pulling Trivy scanner..."
        docker pull aquasec/trivy
    fi
    
    # Run the scan
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image $image_name
    
    echo "✓ Security scan completed"
}

# Function to run Docker Bench Security
invoke_docker_bench_security() {
    echo "Running Docker Bench Security..."
    
    # Check if Docker Bench Security is available
    if ! docker run --rm docker/docker-bench-security --version > /dev/null 2>&1; then
        echo "Pulling Docker Bench Security..."
        docker pull docker/docker-bench-security
    fi
    
    # Run Docker Bench Security
    docker run --rm --net host --pid host --userns host --cap-add audit_control \
    -v /var/lib:/var/lib -v /var/run/docker.sock:/var/run/docker.sock \
    -v /usr/lib/systemd:/usr/lib/systemd -v /etc:/etc --label docker_bench_security \
    docker/docker-bench-security
    
    echo "✓ Docker Bench Security completed"
}

# Function to apply hardened Docker Compose
use_hardened_compose() {
    local apply=$1
    
    if [ "$apply" = "true" ]; then
        echo "Applying hardened Docker Compose configuration..."
        
        # Stop existing containers
        docker-compose down
        
        # Start with hardened configuration
        docker-compose -f docker-compose.hardened.yml up -d
        
        echo "✓ Hardened Docker Compose applied"
    else
        echo "To apply the hardened configuration, run:"
        echo "docker-compose -f docker-compose.hardened.yml up -d"
    fi
}

# Function to check for curl in the container
test_curl_in_container() {
    echo "Checking if curl is available in the SonarQube container..."
    
    if docker ps --filter "name=sonarqube" --format "{{.Names}}" | grep -q sonarqube; then
        if docker exec sonarqube which curl > /dev/null 2>&1; then
            echo "✓ curl is available in the container"
        else
            echo "! curl is not available in the container. Installing..."
            docker exec sonarqube apt-get update
            docker exec sonarqube apt-get install -y curl
            echo "✓ curl installed"
        fi
    else
        echo "! SonarQube container is not running"
    fi
}

# Function to apply AppArmor profiles (Linux-specific)
apply_apparmor_profiles() {
    echo "Checking AppArmor status..."
    
    # Check if AppArmor is installed
    if ! command -v apparmor_status > /dev/null 2>&1; then
        echo "Installing AppArmor..."
        apt-get update
        apt-get install -y apparmor apparmor-utils
    fi
    
    # Check if AppArmor is enabled
    if ! apparmor_status | grep -q "apparmor module is loaded"; then
        echo "AppArmor is not enabled. Please enable AppArmor and reboot."
        return
    fi
    
    echo "Creating Docker AppArmor profile..."
    
    # Create a basic AppArmor profile for Docker containers
    cat > /etc/apparmor.d/docker-sonarqube << EOF
#include <tunables/global>

profile docker-sonarqube flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>
  #include <abstractions/nameservice>

  network,
  capability,
  file,
  umount,

  deny @{PROC}/* w,
  deny @{PROC}/sys/fs/** wklx,
  deny @{PROC}/sysrq-trigger rwklx,
  deny @{PROC}/mem rwklx,
  deny @{PROC}/kmem rwklx,
  deny @{PROC}/kcore rwklx,

  deny mount,

  deny /sys/[^f]*/** wklx,
  deny /sys/f[^s]*/** wklx,
  deny /sys/fs/[^c]*/** wklx,
  deny /sys/fs/c[^g]*/** wklx,
  deny /sys/fs/cg[^r]*/** wklx,
  deny /sys/firmware/** rwklx,
  deny /sys/kernel/security/** rwklx,
}
EOF

    # Parse and load the profile
    apparmor_parser -r /etc/apparmor.d/docker-sonarqube
    
    echo "✓ AppArmor profile created and loaded"
    echo "To use this profile with your container, add '--security-opt apparmor=docker-sonarqube' to your docker run command"
    echo "Or add 'security_opt: [apparmor=docker-sonarqube]' to your service in docker-compose.yml"
}

# Function to configure auditd for Docker (Linux-specific)
configure_docker_audit() {
    echo "Setting up auditd for Docker..."
    
    # Check if auditd is installed
    if ! command -v auditd > /dev/null 2>&1; then
        echo "Installing auditd..."
        apt-get update
        apt-get install -y auditd audispd-plugins
    fi
    
    # Configure Docker audit rules
    cat > /etc/audit/rules.d/docker.rules << EOF
# Docker daemon
-w /usr/bin/dockerd -k docker
-w /var/lib/docker -k docker
-w /etc/docker -k docker
-w /usr/lib/systemd/system/docker.service -k docker
-w /etc/systemd/system/docker.service -k docker
-w /usr/lib/systemd/system/docker.socket -k docker
-w /etc/default/docker -k docker
-w /etc/docker/daemon.json -k docker
-w /usr/bin/docker-containerd -k docker
-w /usr/bin/docker-runc -k docker
-w /var/run/docker.sock -k docker
EOF

    # Restart auditd to apply rules
    service auditd restart
    
    echo "✓ Docker audit rules configured"
    echo "You can view Docker audit logs with: 'ausearch -k docker'"
}

# Main menu
show_menu() {
    echo ""
    echo "Docker Security Hardening Options:"
    echo "1. Apply hardened Docker Compose configuration"
    echo "2. Enable Docker Content Trust"
    echo "3. Scan SonarQube image with Trivy"
    echo "4. Run Docker Bench Security"
    echo "5. Check and install curl in container"
    echo "6. Apply AppArmor profiles (Linux-specific)"
    echo "7. Configure Docker audit with auditd (Linux-specific)"
    echo "8. Exit"
    echo ""
    
    read -p "Enter your choice (1-8): " choice
    
    case $choice in
        1) use_hardened_compose "true" ;;
        2) enable_docker_content_trust ;;
        3) invoke_trivy_scan "sonarqube:latest" ;;
        4) invoke_docker_bench_security ;;
        5) test_curl_in_container ;;
        6) apply_apparmor_profiles ;;
        7) configure_docker_audit ;;
        8) exit ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
    
    show_menu
}

# Start the menu
show_menu