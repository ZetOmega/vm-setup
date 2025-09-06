# bootstrap.ps1
# This version works on a plain Windows install (no git required)

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
# Download vm-setup repo as ZIP
# -----------------------------
$tempZip = "$env:TEMP\vm-setup.zip"
$tempDir = "$env:TEMP\vm-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

Write-Host "Downloading vm-setup repo..."
Invoke-WebRequest "https://github.com/ZetOmega/vm-setup/archive/refs/heads/main.zip" -OutFile $tempZip
Expand-Archive $tempZip -DestinationPath $tempDir

# -----------------------------
# Run setup.ps1
# -----------------------------
$setupScript = Join-Path $tempDir "vm-setup-main\bootstrap.ps1"

# Pass Tailscale info via environment variables
$env:TAILSCALE_KEY = $tailscaleKey
$env:VM_HOSTNAME = $hostname

Write-Host "Running bootstrap.ps1 from vm-setup..."
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$setupScript`"" -Wait

Write-Host "=== Bootstrap Complete ==="
Stop-Transcript
