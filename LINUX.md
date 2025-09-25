# Running SonarQube Docker on Linux

This guide provides specific instructions for running the SonarQube Docker setup on Linux systems.

## System Requirements

SonarQube has specific requirements for Linux systems:

1. Kernel parameters:
   - `vm.max_map_count=262144`
   - `fs.file-max=65536`

2. User limits:
   - `ulimit -n 65536` (open file descriptors)
   - `ulimit -u 4096` (max user processes)

## Quick Setup

1. Make the setup script executable:
   ```bash
   chmod +x linux-setup.sh
   ```

2. Run the setup script as root:
   ```bash
   sudo ./linux-setup.sh
   ```

3. Start SonarQube and PostgreSQL:
   ```bash
   docker-compose up -d
   ```

4. Access SonarQube at: http://localhost:9010

5. Log in with default credentials:
   - Username: `admin`
   - Password: `admin`
   - You'll be prompted to change the password on first login

## Manual Setup

If you prefer to set up manually:

1. Set kernel parameters:
   ```bash
   sudo sysctl -w vm.max_map_count=262144
   sudo sysctl -w fs.file-max=65536
   ```

2. To make these settings permanent, add them to `/etc/sysctl.conf`:
   ```bash
   echo "vm.max_map_count=262144" | sudo tee -a /etc/sysctl.conf
   echo "fs.file-max=65536" | sudo tee -a /etc/sysctl.conf
   ```

3. Set user limits in `/etc/security/limits.conf`:
   ```bash
   echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
   echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf
   echo "* soft nproc 4096" | sudo tee -a /etc/security/limits.conf
   echo "* hard nproc 4096" | sudo tee -a /etc/security/limits.conf
   ```

4. Create `.env` file from template:
   ```bash
   cp .env.template .env
   ```

5. Start the containers:
   ```bash
   docker-compose up -d
   ```

## Troubleshooting

### Permission Issues

If you encounter permission issues with Docker volumes:

```bash
# Check the ownership of the Docker volumes
sudo ls -la /var/lib/docker/volumes/

# If needed, adjust permissions for the SonarQube volumes
sudo chown -R 1000:1000 /var/lib/docker/volumes/sonarqubeserver_sonarqube_*
```

### Memory Issues

If SonarQube fails to start due to memory issues:

1. Check the logs:
   ```bash
   docker logs sonarqube
   ```

2. Verify kernel parameters:
   ```bash
   sysctl vm.max_map_count
   sysctl fs.file-max
   ```

3. Adjust memory settings in `.env` file if needed.

## Security Considerations

1. For production environments, always change default passwords
2. Consider setting up HTTPS with a reverse proxy (like Nginx or Traefik)
3. Apply the security hardening configurations from `security-hardening.env`
4. Implement Docker security hardening measures (see below)

## Docker Security Hardening

This project includes comprehensive Docker security hardening for Linux environments:

### Quick Setup

1. Set up Linux-specific security features:
   ```bash
   sudo ./setup-linux-security.sh
   ```

2. Apply Docker hardening measures:
   ```bash
   sudo ./apply-docker-hardening.sh
   ```

3. Start SonarQube with hardened configuration:
   ```bash
   docker-compose -f docker-compose.hardened.yml up -d
   ```

### Security Features

The Linux Docker hardening implementation includes:

1. **AppArmor Profiles**: Mandatory Access Control for containers
2. **Seccomp Profiles**: System call filtering for containers
3. **Docker Daemon Hardening**: Security configurations for the Docker daemon
4. **Audit Logging**: Monitoring Docker-related activities
5. **Container Hardening**: Non-root users, read-only filesystems, capability restrictions

For detailed information, see [LINUX-DOCKER-HARDENING.md](LINUX-DOCKER-HARDENING.md).