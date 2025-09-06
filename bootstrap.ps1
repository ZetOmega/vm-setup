# bootstrap.ps1
Write-Host "=== Starting VM Setup Bootstrap ==="

# Collect all info once
$env:TAILSCALE_KEY = Read-Host "Enter your Tailscale Auth Key (kept secret)"
$hostname = Read-Host "Enter hostname for this VM (used for Tailscale)"
$env:SUNSHINE_PASSWORD = "sunshine"

# Set hostname
Rename-Computer -NewName $hostname -Force -PassThru

# Prepare temp folder
$tempDir = "$env:TEMP\vm-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Download repo ZIP
$repoZip = "$tempDir\vm-setup.zip"
Write-Host "Downloading vm-setup repo ZIP..."
Invoke-WebRequest -Uri "https://github.com/ZetOmega/vm-setup/archive/refs/heads/main.zip" -OutFile $repoZip

# Unzip
Write-Host "Extracting repo..."
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($repoZip, $tempDir)

# Setup folder
$setupFolder = Join-Path $tempDir "vm-setup-main"

# Call setup.ps1
Write-Host "Running setup.ps1 from vm-setup..."
& "$setupFolder\setup.ps1"
Write-Host "=== Bootstrap Complete ==="
