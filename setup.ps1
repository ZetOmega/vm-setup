# setup.ps1
Write-Host "=== Starting Full VM Setup ==="

# 1. Install Visual C++ Redistributable x64 only
Write-Host "[1/6] Installing Visual C++ Redistributables..."
$vc64 = "Microsoft.VCRedist.2015+.x64"
winget install --id=$vc64 --silent --accept-source-agreements --accept-package-agreements

# 2. Install Sunshine
Write-Host "[2/6] Installing Sunshine..."
$sunshinePassword = $env:SUNSHINE_PASSWORD
winget install --id=LizardByte.Sunshine --silent --accept-source-agreements --accept-package-agreements

# Configure Sunshine password
# (Use local settings file or environment variable, depending on Sunshine's config method)
Write-Host "Setting Sunshine password..."
# Example placeholder, adjust if Sunshine requires registry or config file
# Set-Content -Path "C:\ProgramData\Sunshine\config.json" -Value $sunshinePassword

# 3. Install Steam
Write-Host "[3/6] Installing Steam..."
winget install --id=Valve.Steam --silent --accept-source-agreements --accept-package-agreements

# 4. Install Epic Games Launcher
Write-Host "[4/6] Installing Epic Games Launcher..."
winget install --id=EpicGames.EpicGamesLauncher --silent --accept-source-agreements --accept-package-agreements

# 5. Install Ubisoft Connect
Write-Host "[5/6] Installing Ubisoft Connect..."
winget install --id=Ubisoft.UbisoftConnect --silent --accept-source-agreements --accept-package-agreements

# 6. Install Tailscale (manual installer, older working method)
Write-Host "[6/6] Installing Tailscale..."
$tailscaleUrl = "https://pkgs.tailscale.com/stable/tailscale-setup.exe"
$tailscaleInstaller = "$env:TEMP\tailscale-setup.exe"
Invoke-WebRequest $tailscaleUrl -OutFile $tailscaleInstaller
Start-Process -FilePath $tailscaleInstaller -Wait
Start-Process -FilePath "C:\Program Files (x86)\Tailscale IPN\tailscale.exe" -ArgumentList "up --authkey $env:TAILSCALE_KEY" -Wait

# 7. Install VDD (manual clicking, auto wait)
Write-Host "[7/6] Installing Virtual Display Driver (VDD)..."
$vddInstaller = "$env:TEMP\Virtual.Display.Driver-v24.12.24-setup-x64.exe"
Invoke-WebRequest "https://github.com/ULTRA-VAGUE/Virtual-Display-Driver-Compatibility-Fork/releases/download/v24.12.24/Virtual.Display.Driver-v24.12.24-setup-x64.exe" -OutFile $vddInstaller

Write-Host "Launching VDD installer. Please click through manually..."
$process = Start-Process -FilePath $vddInstaller -PassThru
Write-Host "Waiting for VDD installer to finish..."
$process.WaitForExit()  # Script will pause until you finish clicking through the installer

# Copy VDD config after installer closes
$vddCfg = Join-Path $PSScriptRoot "vdd_settings.xml"
Copy-Item $vddCfg -Destination "C:\ProgramData\VirtualDisplayDriver\vdd_settings.xml" -Force
Write-Host "VDD settings copied."


# 8. NVIDIA drivers
Write-Host "Installing NVIDIA drivers..."
& "$PSScriptRoot\nvidia.ps1"

Write-Host "=== VM Setup Complete! Reboot recommended. ==="
