# setup.ps1

# Ensure running as admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "=== Starting Full Gaming VM Setup ==="

# Prompt for sensitive info
$tailscaleKey = Read-Host -Prompt "Enter your Tailscale Auth Key (kept secret)"
$hostname = Read-Host -Prompt "Enter hostname for this VM (used for Tailscale)"

Write-Host "`nAll required info collected. Beginning installation..."

# -----------------------------
# 1️⃣ Install NVIDIA drivers
# -----------------------------
Write-Host "[1/7] Installing latest NVIDIA driver..."
$nvidiaScriptUrl = "https://raw.githubusercontent.com/lord-carlos/nvidia-update/master/nvidia.ps1"
$nvidiaScriptPath = "$env:TEMP\nvidia.ps1"
Invoke-WebRequest -Uri $nvidiaScriptUrl -OutFile $nvidiaScriptPath

# Run NVIDIA update script silently
Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File $nvidiaScriptPath -clean" -Wait

# -----------------------------
# 2️⃣ Install VC++ Redistributables
# -----------------------------
Write-Host "[2/7] Installing Visual C++ Redistributables..."
$vcUrl = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
$vcExe = "$env:TEMP\vc_redist.x64.exe"
Invoke-WebRequest -Uri $vcUrl -OutFile $vcExe
Start-Process -FilePath $vcExe -ArgumentList "/quiet","/norestart" -Wait

# -----------------------------
# 3️⃣ Install Sunshine
# -----------------------------
Write-Host "[3/7] Installing Sunshine..."
$sunshineUrl = "https://github.com/LizardByte/Sunshine/releases/latest/download/sunshine-windows-installer.exe"
$sunshineExe = "$env:TEMP\sunshine-setup.exe"
Invoke-WebRequest -Uri $sunshineUrl -OutFile $sunshineExe
Start-Process -FilePath $sunshineExe -ArgumentList "/S" -Wait

# Copy Sunshine config
$SunshineCfgDir = "C:\ProgramData\Sunshine\config"
if (!(Test-Path $SunshineCfgDir)) { New-Item -Path $SunshineCfgDir -ItemType Directory -Force }
Copy-Item ".\configs\sunshine.json" -Destination "$SunshineCfgDir\sunshine.json" -Force

# -----------------------------
# 4️⃣ Install Virtual Display Driver
# -----------------------------
Write-Host "[4/7] Installing Virtual Display Driver v24.12.24..."
$vddUrl = "https://github.com/ULTRA-VAGUE/Virtual-Display-Driver-Compatibility-Fork/releases/download/v24.12.24/VirtualDisplayDriver_Setup.exe"
$vddExe = "$env:TEMP\vdd_setup.exe"
Invoke-WebRequest -Uri $vddUrl -OutFile $vddExe
Start-Process -FilePath $vddExe -ArgumentList "/VERYSILENT","/NORESTART" -Wait

# Copy VDD settings
$VddPath = "C:\ProgramData\VirtualDisplayDriver"
if (!(Test-Path $VddPath)) { New-Item -Path $VddPath -ItemType Directory -Force }
Copy-Item ".\configs\vdd_settings.xml" -Destination "$VddPath\vdd_settings.xml" -Force

# -----------------------------
# 5️⃣ Install Tailscale
# -----------------------------
Write-Host "[5/7] Installing Tailscale..."
$tailscaleUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe"
$tailscaleExe = "$env:TEMP\tailscale_setup.exe"
Invoke-WebRequest -Uri $tailscaleUrl -OutFile $tailscaleExe
Start-Process -FilePath $tailscaleExe -ArgumentList "/quiet" -Wait

# Auto-connect with Tailscale key
& "C:\Program Files\Tailscale\tailscale.exe" up --authkey $tailscaleKey --hostname $hostname --accept-routes --accept-dns

# -----------------------------
# 6️⃣ Install Steam
# -----------------------------
Write-Host "[6/7] Installing Steam..."
$steamUrl = "https://cdn.cloudflare.steamstatic.com/client/installer/SteamSetup.exe"
$steamExe = "$env:TEMP\steam_setup.exe"
Invoke-WebRequest -Uri $steamUrl -OutFile $steamExe
Start-Process -FilePath $steamExe -ArgumentList "/S" -Wait

# -----------------------------
# 7️⃣ Install Epic Games Launcher
# -----------------------------
Write-Host "[7/7] Installing Epic Games Launcher..."
$epicUrl = "https://launcher-public-service-prod06.ol.epicgames.com/launcher/api/installer/download/EpicGamesLauncherInstaller.msi"
$epicExe = "$env:TEMP\epic_setup.msi"
Invoke-WebRequest -Uri $epicUrl -OutFile $epicExe
Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$epicExe` /quiet /norestart`"" -Wait

# Optional: Ubisoft Connect
Write-Host "[Optional] Installing Ubisoft Connect..."
$ubisoftUrl = "https://ubisoftconnect.com/setup.exe"
$ubisoftExe = "$env:TEMP\ubisoft_setup.exe"
Invoke-WebRequest -Uri $ubisoftUrl -OutFile $ubisoftExe
Start-Process -FilePath $ubisoftExe -ArgumentList "/S" -Wait

Write-Host "=== Full Setup Complete! Reboot recommended. ==="
