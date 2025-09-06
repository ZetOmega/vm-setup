# bootstrap.ps1
$logFile = "$env:USERPROFILE\Downloads\vm_bootstrap_log.txt"
Start-Transcript -Path $logFile -Append

Write-Host "=== VM Setup Bootstrap ==="

# Ask for sensitive info once
$env:TAILSCALE_KEY = Read-Host "Enter your Tailscale Auth Key (kept secret)"
$env:VM_HOSTNAME = Read-Host "Enter hostname for this VM (used for Tailscale)"

# Ensure temp folder exists
$tempDir = "$env:TEMP\vm-setup"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir }

# Download setup.ps1 if missing
$setupScript = Join-Path $tempDir "setup.ps1"
Invoke-WebRequest "https://raw.githubusercontent.com/ZetOmega/vm-setup/main/setup.ps1" -OutFile $setupScript

# Run setup.ps1
Write-Host "Running setup..."
& $setupScript

Stop-Transcript
