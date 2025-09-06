# setup.ps1
$logFile = "$env:USERPROFILE\Downloads\vm_setup_log.txt"
Start-Transcript -Path $logFile -Append

Write-Host "=== Starting Full VM Setup via Winget ==="

# Read environment variables from bootstrap
$tailscaleKey = $env:TAILSCALE_KEY
$hostname = $env:VM_HOSTNAME

# -----------------------------
# 1️⃣ Install Visual C++ Redistributables via Winget
# -----------------------------
Write-Host "[1/6] Installing Visual C++ Redistributables..."
winget install --id Microsoft.VCRedist.2015+.x64 -e --silent
winget install --id Microsoft.VCRedist.2015+.x86 -e --silent

# -----------------------------
# 2️⃣ Install Sunshine via Winget
# -----------------------------
Write-Host "[2/6] Installing Sunshine..."
winget install --id LizardByte.Sunshine -e --silent
$sunshineCfg = Join-Path $PSScriptRoot "configs\sunshine.json"
if (Test-Path $sunshineCfg) {
    Copy-Item $sunshineCfg -Destination "$env:ProgramData\Sunshine\config\" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Sunshine config not found, skipping..."
}

# -----------------------------
# 3️⃣ Install Game Launchers via Winget
# -----------------------------
Write-Host "[3/6] Installing Game Launchers..."
# Steam
winget install --id Valve.Steam -e --silent
# Epic Games
Start-Process winget -ArgumentList "install EpicGames.EpicGamesLauncher -e --silent" -NoNewWindow
# Ubisoft Connect
winget install --id Ubisoft.UbisoftConnect -e --silent

# -----------------------------
# 4️⃣ Install Tailscale via Winget and connect
# -----------------------------
Write-Host "[4/6] Installing Tailscale..."
winget install --id Tailscale.Tailscale -e --silent
Start-Process "C:\Program Files (x86)\Tailscale IPN\tailscale.exe" -ArgumentList "up --authkey $tailscaleKey --hostname $hostname" -Wait

# -----------------------------
# 5️⃣ Install NVIDIA drivers (using your nvidia.ps1)
# -----------------------------
Write-Host "[5/6] Installing NVIDIA Drivers..."
$nvidiaScript = Join-Path $PSScriptRoot "nvidia.ps1"
if (Test-Path $nvidiaScript) { & $nvidiaScript }

# -----------------------------
# 6️⃣ Install Virtual Display Driver (VDD)
# -----------------------------
Write-Host "[6/6] Installing Virtual Display Driver..."
$vddInstaller = "$env:TEMP\VDDSetup.exe"
Invoke-WebRequest "https://github.com/ULTRA-VAGUE/Virtual-Display-Driver-Compatibility-Fork/releases/download/v24.12.24/Virtual.Display.Driver-v24.12.24-setup-x64.exe" -OutFile $vddInstaller
Start-Process -FilePath $vddInstaller -ArgumentList "/VERYSILENT","/NORESTART" -Wait

# Apply config if exists
$vddCfg = Join-Path $PSScriptRoot "configs\vdd_settings.xml"
if (Test-Path $vddCfg) {
    Copy-Item $vddCfg -Destination "C:\ProgramData\VirtualDisplayDriver\vdd_settings.xml" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "VDD config not found, skipping..."
}

Write-Host "=== VM Setup Complete! Reboot recommended. ==="
Stop-Transcript
