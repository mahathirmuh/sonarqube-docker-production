# Docker Security Hardening for SonarQube on Linux

This document provides instructions for implementing Docker security hardening measures for SonarQube on Linux (Ubuntu) servers.

## Overview

The security hardening implementation includes:

1. **AppArmor Profiles**: Mandatory Access Control (MAC) for containers
2. **Seccomp Profiles**: System call filtering for containers
3. **Docker Daemon Hardening**: Security configurations for the Docker daemon
4. **Audit Logging**: Monitoring Docker-related activities
5. **Container Hardening**: Non-root users, read-only filesystems, capability restrictions

## Prerequisites

- Ubuntu Server (18.04 LTS or newer)
- Docker and Docker Compose installed
- Root access to the server

## Implementation Steps

### 1. Prepare the Environment

First, ensure you have migrated your SonarQube setup from Windows to Linux:

```bash
./windows-to-linux-migration.sh
```

Then run the Linux setup script to configure kernel parameters:

```bash
sudo ./linux-setup.sh
```

### 2. Set Up Linux-Specific Security Features

Run the security setup script to configure AppArmor, seccomp, and audit logging:

```bash
sudo ./setup-linux-security.sh
```

This script will:
- Create and load AppArmor profiles for SonarQube and PostgreSQL
- Set up seccomp profiles to restrict system calls
- Configure audit logging for Docker activities
- Create a hardened Docker daemon configuration

### 3. Apply Docker Hardening

Use the Docker hardening script to apply additional security measures:

```bash
sudo ./apply-docker-hardening.sh
```

This interactive script provides options to:
- Apply the hardened Docker Compose configuration
- Enable Docker Content Trust for image verification
- Scan SonarQube images with Trivy
- Run Docker Bench Security for compliance checks
- Check and install curl in the container (required for health checks)
- Apply AppArmor profiles (Linux-specific)
- Configure Docker audit with auditd (Linux-specific)

### 4. Start SonarQube with Hardened Configuration

Start SonarQube using the hardened Docker Compose file:

```bash
docker-compose -f docker-compose.hardened.yml up -d
```

## Security Features Explained

### AppArmor Profiles

AppArmor profiles (`docker-sonarqube` and `docker-postgres`) restrict what actions containers can perform on the host system. They prevent:

- Writing to sensitive /proc paths
- Mounting filesystems
- Accessing sensitive kernel interfaces
- Modifying system files

### Seccomp Profiles

Seccomp profiles (`sonarqube-seccomp.json` and `postgres-seccomp.json`) restrict which system calls containers can make, reducing the attack surface. The profiles:

- Block dangerous system calls by default
- Allow only necessary system calls for application functionality
- Prevent privilege escalation attempts

### Docker Daemon Hardening

The Docker daemon configuration (`/etc/docker/daemon.json`) includes:

- Disabling inter-container communication (`icc: false`)
- Enabling user namespace remapping (`userns-remap`)
- Configuring logging limits
- Enabling live restore for container availability
- Disabling the userland proxy
- Enforcing no new privileges

### Container-Level Hardening

The `docker-compose.hardened.yml` file implements:

- Non-root user execution
- Read-only root filesystem
- Temporary filesystem for writable directories
- Dropping unnecessary capabilities
- Resource limits (CPU, memory)
- Health checks
- Network restrictions

## Monitoring and Maintenance

### Audit Logs

View Docker-related audit logs:

```bash
sudo ausearch -k docker
```

### AppArmor Status

Check AppArmor profile status:

```bash
sudo aa-status
```

### Security Scanning

Regularly scan your containers for vulnerabilities:

```bash
# Using the script menu
sudo ./apply-docker-hardening.sh
# Select option 3: Scan SonarQube image with Trivy
```

## Troubleshooting

### AppArmor Issues

If containers fail to start with AppArmor errors:

1. Check AppArmor logs:
   ```bash
   sudo dmesg | grep apparmor
   ```

2. Temporarily disable specific profiles for troubleshooting:
   ```bash
   sudo aa-complain docker-sonarqube
   ```

### Seccomp Issues

If applications inside containers malfunction due to seccomp restrictions:

1. Check container logs for "Operation not permitted" errors:
   ```bash
   docker logs sonarqube
   ```

2. Identify missing system calls and add them to the seccomp profile

## Best Practices

1. **Regular Updates**: Keep Docker, container images, and security profiles updated
2. **Monitoring**: Implement continuous monitoring of container activities
3. **Least Privilege**: Always follow the principle of least privilege
4. **Regular Scanning**: Schedule regular vulnerability scans
5. **Backup Profiles**: Maintain backups of working security profiles

## References

- [Docker Security Documentation](https://docs.docker.com/engine/security/)
- [AppArmor Documentation](https://gitlab.com/apparmor/apparmor/-/wikis/home)
- [Seccomp Security Profiles](https://docs.docker.com/engine/security/seccomp/)
- [Docker Bench Security](https://github.com/docker/docker-bench-security)
- [Trivy Container Scanner](https://github.com/aquasecurity/trivy)