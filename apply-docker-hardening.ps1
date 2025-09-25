# Docker Security Hardening Script for SonarQube
# This script applies Docker security best practices to your SonarQube setup

# Ensure we're running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    exit
}

# Display banner
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "      Docker Security Hardening for SonarQube          " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
try {
    docker info | Out-Null
    Write-Host "✓ Docker is running" -ForegroundColor Green
} catch {
    Write-Error "Docker is not running. Please start Docker and try again."
    exit
}

# Function to enable Docker Content Trust
function Enable-DockerContentTrust {
    Write-Host "Enabling Docker Content Trust..." -ForegroundColor Yellow
    $env:DOCKER_CONTENT_TRUST = 1
    [Environment]::SetEnvironmentVariable("DOCKER_CONTENT_TRUST", "1", "Machine")
    Write-Host "✓ Docker Content Trust enabled" -ForegroundColor Green
}

# Function to run security scan with Trivy
function Invoke-TrivyScan {
    param (
        [string]$ImageName
    )
    
    Write-Host "Running security scan on $ImageName..." -ForegroundColor Yellow
    
    # Check if Trivy is available
    try {
        docker run --rm aquasec/trivy --version | Out-Null
    } catch {
        Write-Host "Pulling Trivy scanner..." -ForegroundColor Yellow
        docker pull aquasec/trivy
    }
    
    # Run the scan
    docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image $ImageName
    
    Write-Host "✓ Security scan completed" -ForegroundColor Green
}

# Function to run Docker Bench Security
function Invoke-DockerBenchSecurity {
    Write-Host "Running Docker Bench Security..." -ForegroundColor Yellow
    
    # Check if Docker Bench Security is available
    try {
        docker run --rm docker/docker-bench-security --version | Out-Null
    } catch {
        Write-Host "Pulling Docker Bench Security..." -ForegroundColor Yellow
        docker pull docker/docker-bench-security
    }
    
    # Run Docker Bench Security
    docker run --rm -it --net host --pid host --userns host --cap-add audit_control -v /var/lib:/var/lib -v /var/run/docker.sock:/var/run/docker.sock docker/docker-bench-security
    
    Write-Host "✓ Docker Bench Security completed" -ForegroundColor Green
}

# Function to apply hardened Docker Compose
function Use-HardenedCompose {
    param (
        [switch]$Apply
    )
    
    if ($Apply) {
        Write-Host "Applying hardened Docker Compose configuration..." -ForegroundColor Yellow
        
        # Stop existing containers
        docker-compose down
        
        # Start with hardened configuration
        docker-compose -f docker-compose.hardened.yml up -d
        
        Write-Host "✓ Hardened Docker Compose applied" -ForegroundColor Green
    } else {
        Write-Host "To apply the hardened configuration, run:" -ForegroundColor Yellow
        Write-Host "docker-compose -f docker-compose.hardened.yml up -d" -ForegroundColor White
    }
}

# Function to check for curl in the container
function Test-CurlInContainer {
    Write-Host "Checking if curl is available in the SonarQube container..." -ForegroundColor Yellow
    
    $containerRunning = docker ps --filter "name=sonarqube" --format "{{.Names}}" | Out-String
    
    if ($containerRunning -match "sonarqube") {
        $curlExists = docker exec sonarqube which curl 2>$null
        
        if ($curlExists) {
            Write-Host "✓ curl is available in the container" -ForegroundColor Green
        } else {
            Write-Host "! curl is not available in the container. Installing..." -ForegroundColor Yellow
            docker exec sonarqube apt-get update
            docker exec sonarqube apt-get install -y curl
            Write-Host "✓ curl installed" -ForegroundColor Green
        }
    } else {
        Write-Host "! SonarQube container is not running" -ForegroundColor Yellow
    }
}

# Main menu
function Show-Menu {
    Write-Host ""
    Write-Host "Docker Security Hardening Options:" -ForegroundColor Cyan
    Write-Host "1. Apply hardened Docker Compose configuration"
    Write-Host "2. Enable Docker Content Trust"
    Write-Host "3. Scan SonarQube image with Trivy"
    Write-Host "4. Run Docker Bench Security"
    Write-Host "5. Check and install curl in container"
    Write-Host "6. Exit"
    Write-Host ""
    
    $choice = Read-Host "Enter your choice (1-6)"
    
    switch ($choice) {
        "1" { Use-HardenedCompose -Apply; break }
        "2" { Enable-DockerContentTrust; break }
        "3" { Invoke-TrivyScan -ImageName "sonarqube:latest"; break }
        "4" { Invoke-DockerBenchSecurity; break }
        "5" { Test-CurlInContainer; break }
        "6" { exit }
        default { Write-Host "Invalid choice. Please try again." -ForegroundColor Red }
    }
    
    Show-Menu
}

# Start the menu
Show-Menu