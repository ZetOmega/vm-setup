# =============================
# VM Setup Script
# =============================

Write-Host "=== Starting Full VM Setup ==="

# -----------------------------
# 1️⃣ Visual C++ Redistributables
# -----------------------------
Write-Host "[1/6] Installing Visual C++ Redistributables..."
$vcPackages = @(
    "Microsoft.VCRedist.2015+.x64",
    "Microsoft.VCRedist.2015+.x86"
)
foreach ($pkg in $vcPackages) {
    winget install --id $pkg --accept-source-agreements --accept-package-agreements --silent
}

# -----------------------------
# 2️⃣ Sunshine
# -----------------------------
Write-Host "[2/6] Installing Sunshine..."
winget install --id LizardByte.Sunshine --accept-source-agreements --accept-package-agreements --silent

# -----------------------------
# 3️⃣ Steam & Epic
# -----------------------------
Write-Host "[3/6] Installing Game Launchers..."
$gameLaunchers = @(
    "Valve.Steam",
    "EpicGames.EpicGamesLauncher"
)
foreach ($app in $gameLaunchers) {
    winget install --id $app --accept-source-agreements --accept-package-agreements --silent
}

# -----------------------------
# 4️⃣ Tailscale
# -----------------------------
Write-Host "[4/6] Installing Tailscale (manual method)..."
$tailscaleUrl = "https://pkgs.tailscale.com/stable/tailscale-setup.exe"
$tailscaleInstaller = "$env:TEMP\tailscale-setup.exe"
Invoke-WebRequest $tailscaleUrl -OutFile $tailscaleInstaller

# Run Tailscale installer silently
Start-Process -FilePath $tailscaleInstaller -ArgumentList "/S" -Wait

# Configure Tailscale with your auth key
$env:TAILSCALE_AUTHKEY = Read-Host "Enter your Tailscale Auth Key (kept secret)"
$hostname = Read-Host "Enter hostname for this VM (used for Tailscale)"
Start-Process "$env:ProgramFiles\Tailscale\tailscale.exe" -ArgumentList "up --authkey $env:TAILSCALE_AUTHKEY --hostname $hostname" -Wait

# -----------------------------
# 5️⃣ NVIDIA Drivers
# -----------------------------
Write-Host "[5/6] Installing NVIDIA Drivers..."
$nvidiaScript = "$PSScriptRoot\nvidia.ps1"
& $nvidiaScript

# -----------------------------
# 6️⃣ Virtual Display Driver (VDD)
# -----------------------------
Write-Host "[6/6] Installing Virtual Display Driver (manual)..."
$vddInstaller = "$env:USERPROFILE\Downloads\Virtual.Display.Driver-v24.12.24-setup-x64.exe"

# Run VDD installer manually
Write-Host "Please complete the VDD installation manually. Press Enter here when finished..."
Start-Process $vddInstaller
Read-Host "After finishing the VDD installer, press Enter to continue"

# Copy VDD config after manual install
$vddCfg = "$PSScriptRoot\vdd_settings.xml"
$destination = "C:\ProgramData\VirtualDisplayDriver\vdd_settings.xml"

if (-Not (Test-Path "C:\ProgramData\VirtualDisplayDriver")) {
    New-Item -ItemType Directory -Path "C:\ProgramData\VirtualDisplayDriver"
}

Copy-Item $vddCfg -Destination $destination -Force
Write-Host "VDD settings copied."

Write-Host "=== VM Setup Complete! Reboot recommended. ==="
