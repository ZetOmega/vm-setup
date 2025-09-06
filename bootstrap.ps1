$logFile = "$env:USERPROFILE\Downloads\vm_bootstrap_log.txt"
Start-Transcript -Path $logFile -Append

Write-Host "=== Starting VM Setup Bootstrap ==="

# Collect info once
$env:TAILSCALE_KEY = Read-Host "Enter your Tailscale Auth Key (kept secret)"
$env:VM_HOSTNAME = Read-Host "Enter hostname for this VM (used for Tailscale)"

# Temp folder
$tempDir = Join-Path $env:TEMP "vm-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Download and extract ZIP of repo
$zipUrl = "https://github.com/ZetOmega/vm-setup/archive/refs/heads/main.zip"
$zipFile = Join-Path $tempDir "vm-setup.zip"
Write-Host "Downloading vm-setup ZIP..."
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
Write-Host "Extracting vm-setup..."
Expand-Archive $zipFile -DestinationPath $tempDir -Force

# Determine extracted folder
$setupFolder = Get-ChildItem $tempDir | Where-Object { $_.PSIsContainer -and $_.Name -like "vm-setup*" } | Select-Object -First 1
if (-not $setupFolder) {
    Write-Host "Error: Could not find extracted setup folder!"
    Stop-Transcript
    exit
}
$setupFolderPath = $setupFolder.FullName

# Run setup.ps1
Write-Host "Running setup.ps1 from vm-setup..."
& "$setupFolderPath\setup.ps1"

Stop-Transcript
Write-Host "=== Bootstrap Complete ==="
