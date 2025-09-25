#!/bin/bash
# Script to set up Linux-specific security features for Docker hardening

# Ensure we're running as root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

echo "Setting up Linux-specific security features for Docker hardening..."

# Create directory for seccomp profiles
echo "Creating directory for seccomp profiles..."
mkdir -p /etc/docker/seccomp-profiles

# Copy seccomp profiles
echo "Copying seccomp profiles..."
cp "$(pwd)/sonarqube-seccomp.json" /etc/docker/seccomp-profiles/
cp "$(pwd)/postgres-seccomp.json" /etc/docker/seccomp-profiles/
chmod 644 /etc/docker/seccomp-profiles/*.json

# Check if AppArmor is installed
if ! command -v apparmor_status > /dev/null 2>&1; then
    echo "Installing AppArmor..."
    apt-get update
    apt-get install -y apparmor apparmor-utils
fi

# Check if AppArmor is enabled
if ! apparmor_status | grep -q "apparmor module is loaded"; then
    echo "AppArmor is not enabled. Please enable AppArmor and reboot."
    echo "You can enable it by adding 'apparmor=1 security=apparmor' to your kernel boot parameters."
else
    echo "Creating AppArmor profiles..."
    
    # Create AppArmor profile for SonarQube
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

    # Create AppArmor profile for PostgreSQL
    cat > /etc/apparmor.d/docker-postgres << EOF
#include <tunables/global>

profile docker-postgres flags=(attach_disconnected,mediate_deleted) {
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
  
  # Allow PostgreSQL to write to its data directory
  /var/lib/postgresql/** rwk,
}
EOF

    # Parse and load the profiles
    echo "Loading AppArmor profiles..."
    apparmor_parser -r /etc/apparmor.d/docker-sonarqube
    apparmor_parser -r /etc/apparmor.d/docker-postgres
    
    echo "✓ AppArmor profiles created and loaded"
fi

# Set up auditd for Docker
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

# Create a Docker daemon configuration file with security options
echo "Creating Docker daemon configuration with security options..."

if [ ! -d /etc/docker ]; then
    mkdir -p /etc/docker
fi

cat > /etc/docker/daemon.json << EOF
{
  "icc": false,
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "userns-remap": "default",
  "live-restore": true,
  "userland-proxy": false,
  "no-new-privileges": true,
  "seccomp-profile": "/etc/docker/seccomp-profiles/default.json"
}
EOF

echo "✓ Docker daemon configuration created"

# Restart Docker to apply changes
echo "Restarting Docker service to apply changes..."
systemctl restart docker

echo "\nLinux security setup complete!"
echo "You can now run SonarQube with hardened security using:"
echo "docker-compose -f docker-compose.hardened.yml up -d"