# Docker Security Hardening Implementation Guide

## Implementation Approach

This document outlines the recommended approach for implementing Docker security hardening in your SonarQube setup.

### Phase 1: Preparation (Day 1)

1. **Backup Current Environment**
   - Create a backup of your current Docker volumes
   ```powershell
   docker-compose down
   # Backup volumes to a safe location
   ```

2. **Test Hardened Configuration in Development**
   - Deploy the hardened configuration in a test environment
   - Verify SonarQube functionality remains intact
   ```powershell
   docker-compose -f docker-compose.hardened.yml up -d
   ```

### Phase 2: Implementation (Day 2)

1. **Apply Hardened Docker Compose**
   - Use the provided PowerShell script
   ```powershell
   .\apply-docker-hardening.ps1
   # Select option 1 from the menu
   ```

2. **Enable Docker Content Trust**
   - Verify image signatures for all pulled images
   ```powershell
   $env:DOCKER_CONTENT_TRUST=1
   [Environment]::SetEnvironmentVariable("DOCKER_CONTENT_TRUST", "1", "Machine")
   ```

3. **Configure Host-level Security**
   - Update Docker daemon settings
   ```json
   // /etc/docker/daemon.json
   {
     "icc": false,
     "userns-remap": "default",
     "no-new-privileges": true,
     "live-restore": true,
     "userland-proxy": false,
     "seccomp-profile": "/etc/docker/seccomp-profile.json"
   }
   ```

### Phase 3: Monitoring & Maintenance (Ongoing)

1. **Regular Security Scanning**
   - Schedule weekly vulnerability scans
   ```powershell
   # Add to Task Scheduler
   .\apply-docker-hardening.ps1
   # Select option 3 from the menu
   ```

2. **Audit Docker Environment**
   - Monthly security audits with Docker Bench
   ```powershell
   # Add to Task Scheduler
   .\apply-docker-hardening.ps1
   # Select option 4 from the menu
   ```

3. **Update Images Regularly**
   - Keep SonarQube and PostgreSQL images updated
   ```powershell
   docker-compose pull
   docker-compose -f docker-compose.hardened.yml up -d
   ```

## Security Scanning & Vulnerability Assessment

### 1. Trivy Container Scanner

Trivy is a comprehensive vulnerability scanner for containers.

**Implementation:**
```powershell
# Install Trivy (Windows)
choco install trivy -y

# Scan SonarQube image
trivy image sonarqube:latest

# Scan running container
trivy container sonarqube
```

**Integration with CI/CD:**
```yaml
# Example GitHub Actions workflow
name: Container Security Scan
on: [push, pull_request]
jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'sonarqube:latest'
          format: 'table'
          exit-code: '1'
          severity: 'CRITICAL,HIGH'
```

### 2. Docker Bench Security

Docker Bench checks for dozens of common best practices around deploying Docker containers in production.

**Implementation:**
```powershell
# Run Docker Bench Security
docker run --rm -it --net host --pid host --userns host --cap-add audit_control \
  -v /var/lib:/var/lib -v /var/run/docker.sock:/var/run/docker.sock \
  docker/docker-bench-security
```

### 3. Clair

Clair is an open source project for the static analysis of vulnerabilities in container images.

**Implementation:**
```powershell
# Pull and run Clair
docker run -d --name clair -p 6060:6060 quay.io/coreos/clair:latest

# Scan with clair-scanner
clair-scanner --ip <YOUR_LOCAL_IP> sonarqube:latest
```

### 4. Continuous Monitoring with Prometheus & Grafana

**Implementation:**
```yaml
# Add to docker-compose.hardened.yml
  prometheus:
    image: prom/prometheus:latest
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
    ports:
      - "9090:9090"
    
  grafana:
    image: grafana/grafana:latest
    ports:
      - "3000:3000"
    volumes:
      - grafana_data:/var/lib/grafana
    depends_on:
      - prometheus
```

## Conclusion

This phased approach ensures a smooth transition to a hardened Docker environment while maintaining service availability. Regular scanning and monitoring will help maintain the security posture over time.