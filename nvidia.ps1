# setup.ps1
$logFile = "$env:USERPROFILE\Downloads\vm_setup_log.txt"
Start-Transcript -Path $logFile -Append

Write-Host "=== Starting Full VM Setup ==="

# Read environment variables from bootstrap
$tailscaleKey = $env:TAILSCALE_KEY
$hostname = $env:VM_HOSTNAME

# -----------------------------
# 1️⃣ Install Visual C++ Redistributables
# -----------------------------
Write-Host "[1/7] Installing Visual C++ Redistributables..."
$vcredistX86 = "$PSScriptRoot\installers\vc_redist.x86.exe"
$vcredistX64 = "$PSScriptRoot\installers\vc_redist.x64.exe"
if (Test-Path $vcredistX86) { Start-Process -FilePath $vcredistX86 -ArgumentList "/quiet","/norestart" -Wait }
if (Test-Path $vcredistX64) { Start-Process -FilePath $vcredistX64 -ArgumentList "/quiet","/norestart" -Wait }

# -----------------------------
# 2️⃣ Install Sunshine
# -----------------------------
Write-Host "[2/7] Installing Sunshine..."
$sunshineCfg = Join-Path $PSScriptRoot "configs\sunshine.json"
$sunshineInstaller = "$env:TEMP\SunshineSetup.exe"
Invoke-WebRequest "https://github.com/LizardByte/Sunshine/releases/latest/download/SunshineSetup.exe" -OutFile $sunshineInstaller
Start-Process -FilePath $sunshineInstaller -ArgumentList "/SILENT" -Wait
if (Test-Path $sunshineCfg) {
    Copy-Item $sunshineCfg -Destination "$env:ProgramData\Sunshine\config\" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "Sunshine config not found, skipping..."
}

# -----------------------------
# 3️⃣ Install Virtual Display Driver (VDD)
# -----------------------------
Write-Host "[3/7] Installing Virtual Display Driver..."
$vddInstaller = "$env:TEMP\VDDSetup.exe"
Invoke-WebRequest "https://github.com/ULTRA-VAGUE/Virtual-Display-Driver-Compatibility-Fork/releases/download/v24.12.24/Virtual.Display.Driver-v24.12.24-setup-x64.exe" -OutFile $vddInstaller
Start-Process -FilePath $vddInstaller -ArgumentList "/VERYSILENT","/NORESTART" -Wait
$vddCfg = Join-Path $PSScriptRoot "configs\vdd_settings.xml"
if (Test-Path $vddCfg) {
    Copy-Item $vddCfg -Destination "C:\ProgramData\VirtualDisplayDriver\vdd_settings.xml" -Force -ErrorAction SilentlyContinue
} else {
    Write-Host "VDD config not found, skipping..."
}

# -----------------------------
# 4️⃣ Install Tailscale
# -----------------------------
Write-Host "[4/7] Installing Tailscale..."
$tailscaleInstaller = "$env:TEMP\TailscaleSetup.msi"
Invoke-WebRequest "https://pkgs.tailscale.com/stable/tailscale-ipn-windows-amd64.msi" -OutFile $tailscaleInstaller
Start-Process msiexec.exe -ArgumentList "/i `"$tailscaleInstaller` /quiet /norestart" -Wait
Start-Process "C:\Program Files (x86)\Tailscale IPN\tailscale.exe" -ArgumentList "up --authkey $tailscaleKey --hostname $hostname" -Wait

# -----------------------------
# 5️⃣ Install Steam / Epic / Ubisoft launchers
# -----------------------------
Write-Host "[5/7] Installing Game Launchers..."
$steamInstaller = "$PSScriptRoot\installers\SteamSetup.exe"
$epicInstaller = "$PSScriptRoot\installers\EpicInstaller.msi"
$ubisoftInstaller = "$PSScriptRoot\installers\UbisoftConnectInstaller.exe"

if (Test-Path $steamInstaller) { Start-Process -FilePath $steamInstaller -ArgumentList "/SILENT" -Wait }
if (Test-Path $epicInstaller) { Start-Process msiexec.exe -ArgumentList "/i `"$epicInstaller` /quiet /norestart" -Wait }
if (Test-Path $ubisoftInstaller) { Start-Process -FilePath $ubisoftInstaller -ArgumentList "/SILENT" -Wait }

# -----------------------------
# 6️⃣ Install NVIDIA Drivers
# -----------------------------
Write-Host "[6/7] Installing NVIDIA Drivers..."
$nvidiaScript = Join-Path $PSScriptRoot "nvidia.ps1"
if (Test-Path $nvidiaScript) {
    & $nvidiaScript
} else {
    Write-Host "NVIDIA script not found, skipping..."
}

# -----------------------------
# 7️⃣ Finalization
# -----------------------------
Write-Host "[7/7] VM Setup Complete! Please reboot manually if needed."
Stop-Transcript
