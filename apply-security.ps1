# PowerShell script to apply security hardening configurations to SonarQube

# Check if running as administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "Please run this script as Administrator!"
    exit
}

Write-Host "Applying SonarQube security hardening configurations..." -ForegroundColor Green

# Load environment variables from security-hardening.env
$envFile = "$PSScriptRoot\security-hardening.env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^([^#][^=]+)=(.*)$') {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Write-Host "Setting $name environment variable" -ForegroundColor Cyan
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }
} else {
    Write-Error "Security hardening environment file not found: $envFile"
    exit 1
}

# Update docker-compose.yml with security configurations
$dockerComposeFile = "$PSScriptRoot\docker-compose.yml"
if (Test-Path $dockerComposeFile) {
    $dockerCompose = Get-Content $dockerComposeFile -Raw
    
    # Create backup of original docker-compose.yml
    Copy-Item $dockerComposeFile "$dockerComposeFile.bak" -Force
    Write-Host "Created backup of docker-compose.yml" -ForegroundColor Yellow
    
    # Add security configurations
    Write-Host "Updating docker-compose.yml with security configurations..." -ForegroundColor Cyan
    
    # Add environment variables from security-hardening.env
    $envVars = Get-Content $envFile | Where-Object { $_ -match '^([^#][^=]+)=(.*)$' } | ForEach-Object { "      - $($matches[1])=$($matches[2])" }
    
    # Update docker-compose.yml
    $updatedDockerCompose = $dockerCompose -replace '(sonarqube:\s*\n.*?environment:\s*\n(?:.*?\n)*?)(\s*ports:)', "`$1$($envVars -join "`n")`n`$2"
    
    # Save updated docker-compose.yml
    $updatedDockerCompose | Set-Content $dockerComposeFile -Force
    
    Write-Host "Docker Compose file updated successfully!" -ForegroundColor Green
} else {
    Write-Error "Docker Compose file not found: $dockerComposeFile"
    exit 1
}

# Set system requirements for Windows
Write-Host "Setting system requirements for SonarQube..." -ForegroundColor Cyan

# Set SonarQube Java options environment variable
[Environment]::SetEnvironmentVariable("SONARQUBE_JAVAOPTS", "-Xmx2G -Xms1G", "Machine")
Write-Host "Set SONARQUBE_JAVAOPTS environment variable" -ForegroundColor Green

# Recommend increasing virtual memory
Write-Host "\nRECOMMENDATION: Increase virtual memory (pagefile) to at least 4GB" -ForegroundColor Yellow
Write-Host "1. Open System Properties > Advanced > Performance > Settings > Advanced > Virtual Memory > Change" -ForegroundColor Yellow
Write-Host "2. Set Initial size and Maximum size to at least 4096 MB" -ForegroundColor Yellow

Write-Host "\nSecurity hardening configurations applied successfully!" -ForegroundColor Green
Write-Host "Restart Docker and run 'docker-compose up -d' to apply changes." -ForegroundColor Cyan