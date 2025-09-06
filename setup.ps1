# Setup.ps1
$logFile = "$env:USERPROFILE\Downloads\vm_setup_log.txt"
Start-Transcript -Path $logFile -Append

Write-Host "=== Starting Full VM Setup ==="

# 1️⃣ Install Visual C++ Redistributables (silent)
winget install --id Microsoft.VCRedist.2015+.x64 -e --accept-package-agreements --accept-source-agreements
winget install --id Microsoft.VCRedist.2015+.x86 -e --accept-package-agreements --accept-source-agreements

# 2️⃣ Sunshine
winget install --id LizardByte.Sunshine -e --accept-package-agreements --accept-source-agreements
$SunshineCfgDir = "C:\ProgramData\Sunshine\config"
if (Test-Path "$PSScriptRoot\configs\sunshine.json") {
    Copy-Item "$PSScriptRoot\configs\sunshine.json" -Destination $SunshineCfgDir -Force
} else {
    Write-Host "Sunshine config not found, skipping..."
}

# 3️⃣ Game Launchers
$gameLaunchers = @(
    "Valve.Steam",
    "EpicGames.EpicGamesLauncher",
    "Ubisoft.UbisoftConnect"
)

foreach ($launcher in $gameLaunchers) {
    winget install --id $launcher -e --accept-package-agreements --accept-source-agreements
}

# 4️⃣ Tailscale (manual installer)
$tailscaleUrl = "https://pkgs.tailscale.com/stable/tailscale-setup.exe"
$tailscaleInstaller = Join-Path $env:TEMP "tailscale-setup.exe"
Invoke-WebRequest $tailscaleUrl -OutFile $tailscaleInstaller
Start-Process -FilePath $tailscaleInstaller -ArgumentList "/S" -Wait

# Auto-connect
$tailscaleExe = "C:\Program Files (x86)\Tailscale IPN\tailscale.exe"
Start-Process $tailscaleExe -ArgumentList "up --authkey $env:TAILSCALE_KEY --hostname $env:VM_HOSTNAME" -Wait

# 5️⃣ VDD install
$vddUrl = "https://github.com/ULTRA-VAGUE/Virtual-Display-Driver-Compatibility-Fork/releases/download/v24.12.24/Virtual.Display.Driver-v24.12.24-setup-x64.exe"
$vddExe = Join-Path $env:TEMP "VDD-setup.exe"
Invoke-WebRequest -Uri $vddUrl -OutFile $vddExe
Start-Process -FilePath $vddExe -ArgumentList "/VERYSILENT","/SUPPRESSMSGBOXES","/NORESTART" -Wait

# Copy VDD config if exists
$vddCfg = Join-Path $PSScriptRoot "configs\vdd_settings.xml"
if (Test-Path $vddCfg) {
    Copy-Item $vddCfg -Destination "C:\ProgramData\VirtualDisplayDriver\vdd_settings.xml" -Force
    Write-Host "VDD config copied."
} else {
    Write-Host "VDD config not found, skipping..."
}

# 6️⃣ NVIDIA driver
& "$PSScriptRoot\nvidia.ps1"

Stop-Transcript
Write-Host "=== VM Setup Complete! Reboot recommended ==="
