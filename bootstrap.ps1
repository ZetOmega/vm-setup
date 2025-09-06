$logFile = "$env:USERPROFILE\Downloads\vm_bootstrap_log.txt"
Start-Transcript -Path $logFile -Append

Write-Host "=== Starting VM Setup Bootstrap ==="

# Collect sensitive info once
$env:TAILSCALE_KEY = Read-Host "Enter your Tailscale Auth Key (kept secret)"
$env:VM_HOSTNAME = Read-Host "Enter hostname for this VM (used for Tailscale)"

# Temp folder for repo
$tempDir = Join-Path $env:TEMP "vm-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Check if Git is installed
$gitInstalled = Get-Command git -ErrorAction SilentlyContinue
if (-not $gitInstalled) {
    Write-Host "Git not found. Installing Git silently via winget..."
    winget install --id Git.Git -e --silent --accept-package-agreements --accept-source-agreements
}

# Clone repo
Write-Host "Downloading vm-setup repo via git..."
git clone https://github.com/ZetOmega/vm-setup.git $tempDir

# Run setup.ps1 from cloned repo
$setupFolder = Join-Path $tempDir "vm-setup"
Write-Host "Running setup.ps1 from vm-setup..."
& "$setupFolder\setup.ps1"

Stop-Transcript
Write-Host "=== Bootstrap Complete ==="
