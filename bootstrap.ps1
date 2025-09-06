# bootstrap.ps1
$logFile = "$env:USERPROFILE\Downloads\vm_bootstrap_log.txt"
Start-Transcript -Path $logFile -Append

# Admin check
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "=== Starting VM Setup Bootstrap ==="

# Prompt once for sensitive info
$env:TAILSCALE_KEY = Read-Host -Prompt "Enter your Tailscale Auth Key (kept secret)"
$env:VM_HOSTNAME = Read-Host -Prompt "Enter hostname for this VM (used for Tailscale)"

# Download vm-setup repo ZIP
$tempZip = "$env:TEMP\vm-setup.zip"
$tempDir = "$env:TEMP\vm-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

Write-Host "Downloading vm-setup repo..."
Invoke-WebRequest "https://github.com/ZetOmega/vm-setup/archive/refs/heads/main.zip" -OutFile $tempZip
Expand-Archive $tempZip -DestinationPath $tempDir -Force

# Run setup.ps1
$setupScript = Join-Path $tempDir "vm-setup-main\setup.ps1"
Write-Host "Running setup.ps1 from vm-setup..."
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$setupScript`"" -Wait

Write-Host "=== Bootstrap Complete ==="
Stop-Transcript
