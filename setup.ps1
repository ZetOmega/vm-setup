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

# Install Ubisoft Connect (simplified)
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
            Start-Process -FilePath $tailscaleInstaller -ArgumentList
