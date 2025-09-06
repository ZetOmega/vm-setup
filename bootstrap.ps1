# bootstrap.ps1
Write-Host "=== Starting VM Setup Bootstrap ==="

# Collect all info once
$env:TAILSCALE_KEY = Read-Host "Enter your Tailscale Auth Key (kept secret)"
$hostname = Read-Host "Enter hostname for this VM (used for Tailscale)"
$env:SUNSHINE_PASSWORD = "sunshine"

# Set hostname
Rename-Computer -NewName $hostname -Force -PassThru

# Install 7zip first for NVIDIA driver extraction
Write-Host "Installing 7-Zip..." -ForegroundColor Cyan
winget install --id 7zip.7zip -e --source winget --accept-package-agreements --accept-source-agreements --silent

# Prepare temp folder
$tempDir = "$env:TEMP\vm-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Download repo ZIP
$repoZip = "$tempDir\vm-setup.zip"
Write-Host "Downloading vm-setup repo ZIP..."
try {
    Invoke-WebRequest -Uri "https://github.com/ZetOmega/vm-setup/archive/refs/heads/main.zip" -OutFile $repoZip -ErrorAction Stop
} catch {
    Write-Warning "Failed to download repo: $($_.Exception.Message)"
    exit 1
}

# Unzip
Write-Host "Extracting repo..."
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($repoZip, $tempDir)
} catch {
    Write-Warning "Failed to extract repo: $($_.Exception.Message)"
    # Fallback to PowerShell extraction
    Expand-Archive -Path $repoZip -DestinationPath $tempDir -Force
}

# Setup folder
$setupFolder = Join-Path $tempDir "vm-setup-main"

# Call setup.ps1
Write-Host "Running setup.ps1 from vm-setup..."
if (Test-Path "$setupFolder\setup.ps1") {
    & "$setupFolder\setup.ps1"
} else {
    Write-Error "setup.ps1 not found in extracted files"
    exit 1
}

Write-Host "=== Bootstrap Complete ==="
