# setup.ps1 - Modular installation functions

# Install Visual C++ Redistributable
function Install-VCRedist {
    Write-Host "[1] Installing Visual C++ Redistributables..." -ForegroundColor Cyan
    $vc64 = "Microsoft.VCRedist.2015+.x64"
    try {
        winget install --id=$vc64 --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Visual C++ installed successfully" -ForegroundColor Green
        return $true
    } 
    catch {
        Write-Warning "Visual C++ installation failed: $($_.Exception.Message)"
        return $false
    }
}

# Install Sunshine
function Install-Sunshine {
    Write-Host "[2] Installing Sunshine..." -ForegroundColor Cyan
    try {
        winget install --id=LizardByte.Sunshine --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Sunshine installed successfully" -ForegroundColor Green
        return $true
    } 
    catch {
        Write-Warning "Sunshine installation failed: $($_.Exception.Message)"
        return $false
    }
}

# Install Steam
function Install-Steam {
    Write-Host "[3] Installing Steam..." -ForegroundColor Cyan
    try {
        winget install --id=Valve.Steam --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Steam installed successfully" -ForegroundColor Green
        return $true
    } 
    catch {
        Write-Warning "Steam installation failed: $($_.Exception.Message)"
        return $false
    }
}

# Install Epic Games Launcher
function Install-Epic {
    Write-Host "[4] Installing Epic Games Launcher..." -ForegroundColor Cyan
    try {
        winget install --id=EpicGames.EpicGamesLauncher --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Epic Games Launcher installed successfully" -ForegroundColor Green
        return $true
    } 
    catch {
        Write-Warning "Epic Games Launcher installation failed: $($_.Exception.Message)"
        return $false
    }
}

# Install Ubisoft Connect
function Install-Ubisoft {
    Write-Host "[5] Installing Ubisoft Connect..." -ForegroundColor Cyan
    try {
        winget install --id=Ubisoft.Connect --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Ubisoft Connect installed successfully" -ForegroundColor Green
        return $true
    } 
    catch {
        Write-Warning "Ubisoft Connect installation failed: $($_.Exception.Message)"
        return $false
    }
}

# Install Tailscale
function Install-Tailscale {
    Write-Host "[6] Installing Tailscale..." -ForegroundColor Cyan
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
                return $true
            } 
            else {
                Write-Warning "Tailscale executable not found. Please configure manually."
                return $false
            }
        }
    } 
    catch {
        Write-Warning "Tailscale installation failed: $($_.Exception.Message)"
        return $false
    }
}

# Install VDD
function Install-VDD {
    Write-Host "[7] Installing Virtual Display Driver (VDD)..." -ForegroundColor Cyan
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
    } 
    catch {
        Write-Warning "VDD download failed: $($_.Exception.Message)"
        return $false
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
    } 
    else {
        Write-Warning "VDD settings file not found at: $vddCfg"
    }


# Install Parsec
function Install-Parsec {
    Write-Host "[8] Installing Parsec..." -ForegroundColor Cyan
    try {
        winget install --id=Parsec.Parsec --silent --accept-source-agreements --accept-package-agreements
        Write-Host "Parsec installed successfully" -ForegroundColor Green
        return $true
    } 
    catch {
        Write-Warning "Parsec installation failed: $($_.Exception.Message)"
        return $false
    }
}

# Install NVIDIA drivers
function Install-NvidiaDrivers {
    Write-Host "[9] Installing NVIDIA drivers..." -ForegroundColor Cyan
    if (Test-Path "$PSScriptRoot\nvidia.ps1") {
        & "$PSScriptRoot\nvidia.ps1"
        return $true
    } 
    else {
        Write-Warning "nvidia.ps1 not found. Skipping NVIDIA driver installation."
        return $false
    }
}

# Export functions so they can be called from bootstrap
Export-ModuleMember -Function *
