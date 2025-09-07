# setup.ps1
Write-Host "=== Starting Full VM Setup ==="

# Set default values if environment variables are not set
$installSunshine = [bool]($env:INSTALL_SUNSHINE -eq "True")
$installParsec = [bool]($env:INSTALL_PARSEC -eq "True")
$installSteam = [bool]($env:INSTALL_STEAM -eq "True")
$installEpic = [bool]($env:INSTALL_EPIC -eq "True")
$installUbisoft = [bool]($env:INSTALL_UBISOFT -eq "True")
$installNvidia = [bool]($env:INSTALL_NVIDIA -eq "True")

# 1. Install Visual C++ Redistributable x64 only (always install)
Write-Host "[1/6] Installing Visual C++ Redistributables..." -ForegroundColor Cyan
$vc64 = "Microsoft.VCRedist.2015+.x64"
try {
    winget install --id=$vc64 --silent --accept-source-agreements --accept-package-agreements
    Write-Host "Visual C++ installed successfully" -ForegroundColor Green
} catch {
    Write-Warning "Visual C++ installation failed: $($_.Exception.Message)"
}

# 2. Install Sunshine if selected
if ($installSunshine) {
    Write-Host "[2/6] Installing Sunshine..." -ForegroundColor Cyan
    try {
        winget install --id=LizardByte.Sunshine --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Sunshine installed successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Sunshine installation failed: $($_.Exception.Message)"
    }
}

# 3. Install Steam if selected
if ($installSteam) {
    Write-Host "[3/6] Installing Steam..." -ForegroundColor Cyan
    try {
        winget install --id=Valve.Steam --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Steam installed successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Steam installation failed: $($_.Exception.Message)"
    }
}

# 4. Install Epic Games Launcher if selected
if ($installEpic) {
    Write-Host "[4/6] Installing Epic Games Launcher..." -ForegroundColor Cyan
    try {
        winget install --id=EpicGames.EpicGamesLauncher --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Epic Games Launcher installed successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Epic Games Launcher installation failed: $($_.Exception.Message)"
    }
}

# 5. Install Ubisoft Connect if selected
if ($installUbisoft) {
    Write-Host "[5/6] Installing Ubisoft Connect..." -ForegroundColor Cyan
    try {
        winget install --id=Ubisoft.Connect --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Ubisoft Connect installed successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Ubisoft Connect installation failed: $($_.Exception.Message)"
    }
}

# 6. Install Tailscale if Sunshine is selected
if ($installSunshine) {
    Write-Host "[6/6] Installing Tailscale..." -ForegroundColor Cyan
    $tailscaleUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe"
    $tailscaleInstaller = "$env:TEMP\tailscale-setup.exe"
    try {
        Invoke-WebRequest $tailscaleUrl -OutFile $tailscaleInstaller -ErrorAction Stop
        if (Test-Path $tailscaleInstaller) {
            Write-Host "Starting Tailscale installation..." -ForegroundColor Yellow
            Start-Process -FilePath $tailscaleInstaller -ArgumentList "/S" -Wait
            Start-Sleep -Seconds 10
            $tailscalePaths = @(
                "C:\Program Files\Tailscale\tailscale.exe",
                "C:\Program Files (x86)\Tailscale IPN\tailscale.exe"
            )
            $tailscaleExe = $tailscalePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
            if ($tailscaleExe) {
                Write-Host "Configuring Tailscale with auth key..." -ForegroundColor Yellow
                Start-Process -FilePath $tailscaleExe -ArgumentList "up", "--authkey", "$env:TAILSCALE_KEY", "--reset" -Wait
                Write-Host "Tailscale configured successfully" -ForegroundColor Green
            } else {
                Write-Warning "Tailscale executable not found. Please configure manually."
            }
        }
    } catch {
        Write-Warning "Tailscale installation failed: $($_.Exception.Message)"
    }
}

# 7. Install VDD if Sunshine is selected
if ($installSunshine) {
    Write-Host "[7/6] Installing Virtual Display Driver (VDD)..." -ForegroundColor Cyan
    $vddInstaller = "$env:TEMP\VirtualDisplayDriverSetup.exe"

    try {
        # Download VDD installer
        Write-Host "Downloading VDD installer..." -ForegroundColor Yellow
        $vddUrl = "https://github.com/ULTRA-VAGUE/Virtual-Display-Driver-Compatibility-Fork/releases/download/v24.12.24/Virtual.Display.Driver-v24.12.24-setup-x64.exe"
        Invoke-WebRequest -Uri $vddUrl -OutFile $vddInstaller -ErrorAction Stop
        
        if (Test-Path $vddInstaller) {
            Write-Host "Opening VDD installer for manual installation..." -ForegroundColor Yellow
            Write-Host "Please complete the VDD installation in the window that opens" -ForegroundColor Yellow
            
            # Run the installer
            Start-Process -FilePath $vddInstaller
            
            Write-Host "Press any key after you have completed the VDD installation..." -ForegroundColor Green
            $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown") | Out-Null
            
            Write-Host "VDD installation completed" -ForegroundColor Green
        }
    } catch {
        Write-Warning "VDD download failed: $($_.Exception.Message)"
    }

    # Copy VDD configuration after manual installation
    Write-Host "Copying VDD configuration..." -ForegroundColor Cyan
    $vddCfg = Join-Path $PSScriptRoot "vdd_settings.xml"
    $vddDestDir = "C:\VirtualDisplayDriver"
    $vddDest = "$vddDestDir\vdd_settings.xml"

    if (Test-Path $vddCfg) {
        if (-not (Test-Path $vddDestDir)) {
            New-Item -ItemType Directory -Path $vddDestDir -Force
        }
        Copy-Item $vddCfg -Destination $vddDest -Force
        Write-Host "VDD settings copied to: $vddDest" -ForegroundColor Green
    } else {
        Write-Warning "VDD settings file not found at: $vddCfg"
    }

    # Clean up installer
    if (Test-Path $vddInstaller) {
        Remove-Item $vddInstaller -Force -ErrorAction SilentlyContinue
    }

    Write-Host "VDD setup completed!" -ForegroundColor Green
}

# 8. Install Parsec if selected
if ($installParsec) {
    Write-Host "[8/6] Installing Parsec..." -ForegroundColor Cyan
    try {
        winget install --id=Parsec.Parsec --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Parsec installed successfully" -ForegroundColor Green
    } catch {
        Write-Warning "Parsec installation failed: $($_.Exception.Message)"
    }
}

# 9. NVIDIA drivers if selected
if ($installNvidia) {
    Write-Host "Installing NVIDIA drivers..." -ForegroundColor Cyan
    if (Test-Path "$PSScriptRoot\nvidia.ps1") {
        & "$PSScriptRoot\nvidia.ps1"
    } else {
        Write-Warning "nvidia.ps1 not found. Skipping NVIDIA driver installation."
    }
}

Write-Host "=== VM Setup Complete! Reboot recommended. ===" -ForegroundColor Green
