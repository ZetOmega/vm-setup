# Bootstrap.ps1
$logFile = "$env:USERPROFILE\Downloads\vm_bootstrap_log.txt"
Start-Transcript -Path $logFile -Append

Write-Host "=== Starting VM Setup Bootstrap ==="

# Collect sensitive info once
$env:TAILSCALE_KEY = Read-Host "Enter your Tailscale Auth Key (kept secret)"
$env:VM_HOSTNAME = Read-Host "Enter hostname for this VM (used for Tailscale)"

# Temp folder for full repo
$tempDir = Join-Path $env:TEMP "vm-setup"

# Remove if exists (force fresh clone)
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }

# Clone repo (requires Git)
git clone https://github.com/ZetOmega/vm-setup.git $tempDir

# Run setup from cloned repo
Write-Host "Running setup.ps1 from vm-setup..."
& "$tempDir\setup.ps1"

Stop-Transcript
Write-Host "=== Bootstrap Complete ==="
