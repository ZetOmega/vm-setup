# bootstrap.ps1
# This script downloads your vm-setup repo and runs setup.ps1

# -----------------------------
# Setup Logging
# -----------------------------
$logFile = "$env:USERPROFILE\Downloads\vm_bootstrap_log.txt"
Start-Transcript -Path $logFile -Append

# Ensure running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "=== Starting VM Setup Bootstrap ==="

# Prompt for sensitive info
$tailscaleKey = Read-Host -Prompt "Enter your Tailscale Auth Key (kept secret)"
$hostname = Read-Host -Prompt "Enter hostname for this VM (used for Tailscale)"

# -----------------------------
# Download vm-setup repo
# -----------------------------
$tempDir = "$env:TEMP\vm-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
Write-Host "Downloading vm-setup repo..."
git clone https://github.com/ZetOmega/vm-setup.git $tempDir

# -----------------------------
# Run setup.ps1
# -----------------------------
$setupScript = Join-Path $tempDir "setup.ps1"

# Pass Tailscale info via environment variables so setup.ps1 can use them
$env:TAILSCALE_KEY = $tailscaleKey
$env:VM_HOSTNAME = $hostname

Write-Host "Running setup.ps1 from vm-setup..."
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$setupScript`"" -Wait

Write-Host "=== Bootstrap Complete ==="
Stop-Transcript
