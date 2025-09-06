# setup.ps1
Write-Host "=== Starting Full VM Setup ==="

# 1. Install Visual C++ Redistributable x64 only
Write-Host "[1/6] Installing Visual C++ Redistributables..." -ForegroundColor Cyan
$vc64 = "Microsoft.VCRedist.2015+.x64"
try {
    winget install --id=$vc64 --silent --accept-source-agreements --accept-package-agreements
    Write-Host "Visual C++ installed successfully" -ForegroundColor Green
} catch {
    Write-Warning "Visual C++ installation failed: $($_.Exception.Message)"
}

# 2. Install Sunshine
Write-Host "[2/6] Installing Sunshine..." -ForegroundColor Cyan
try {
    winget install --id=LizardByte.Sunshine --silent --accept-source-agreements --accept-package-agreements
    Write-Host "Sunshine installed successfully" -ForegroundColor Green
} catch {
    Write-Warning "Sunshine installation failed: $($_.Exception.Message)"
}

# Configure Sunshine password (placeholder)
Write-Host "Sunshine password set to: $env:SUNSHINE_PASSWORD" -ForegroundColor Yellow

# 3. Install Steam
Write-Host "[3/6] Installing Steam..." -ForegroundColor Cyan
try {
    winget install --id=Valve.Steam --silent --accept-source-agreements --accept-package-agreements
    Write-Host "Steam installed successfully" -ForegroundColor Green
} catch {
    Write-Warning "Steam installation failed: $($_.Exception.Message)"
}

# 4. Install Epic Games Launcher
Write-Host "[4/6] Installing Epic Games Launcher..." -ForegroundColor Cyan
try {
    winget install --id=EpicGames.EpicGamesLauncher --silent --accept-source-agreements --accept-package-agreements
    Write-Host "Epic Games Launcher installed successfully" -ForegroundColor Green
} catch {
    Write-Warning "Epic Games Launcher installation failed: $($_.Exception.Message)"
}

# 5. Install Ubisoft Connect
Write-Host "[5/6] Installing Ubisoft Connect..." -ForegroundColor Cyan

# Method 1: Using winget (recommended - silent install)
try {
    Write-Host "Installing Ubisoft Connect via winget..." -ForegroundColor Yellow
    winget install --id=Ubisoft.Connect --silent --accept-source-agreements --accept-package-agreements
    Write-Host "Ubisoft Connect installed successfully via winget" -ForegroundColor Green
} catch {
    Write-Warning "Winget installation failed: $($_.Exception.Message)"
    
    # Method 2: Direct download and silent install (fallback)
    Write-Host "Trying direct download method..." -ForegroundColor Yellow
    $ubisoftUrl = "https://ubistatic3-a.akamaihd.net/orbit/launcher_installer/UbisoftConnectInstaller.exe"
    $ubisoftInstaller = "$env:TEMP\UbisoftConnectInstaller.exe"
    
    try {
        # Download installer
        Invoke-WebRequest -Uri $ubisoftUrl -OutFile $ubisoftInstaller -ErrorAction Stop
        
        if (Test-Path $ubisoftInstaller) {
            Write-Host "Running Ubisoft Connect installer silently..." -ForegroundColor Yellow
            
            # Silent install parameters
            $installArgs = "/S"
            
            # Install silently
            $process = Start-Process -FilePath $ubisoftInstaller -ArgumentList $installArgs -Wait -PassThru
            
            if ($process.ExitCode -eq 0) {
                Write-Host "Ubisoft Connect installed successfully" -ForegroundColor Green
            } else {
                Write-Warning "Installer exited with code: $($process.ExitCode)"
                
                # Try alternative silent method
                Write-Host "Trying alternative installation method..." -ForegroundColor Yellow
                Start-Process -FilePath $ubisoftInstaller -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
                
                # Verify installation
                if (Test-Path "${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher\upc.exe") {
                    Write-Host "Ubisoft Connect installed successfully" -ForegroundColor Green
                } else {
                    Write-Warning "Ubisoft Connect installation may have failed"
                }
            }
            
            # Cleanup installer
            Remove-Item $ubisoftInstaller -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "Direct download installation also failed: $($_.Exception.Message)"
        Write-Host "Please install Ubisoft Connect manually from: https://ubisoftconnect.com" -ForegroundColor Yellow
    }
}

# Verify installation
$ubisoftPaths = @(
    "${env:ProgramFiles(x86)}\Ubisoft\Ubisoft Game Launcher",
    "${env:ProgramFiles}\Ubisoft\Ubisoft Game Launcher",
    "$env:LOCALAPPDATA\Ubisoft Game Launcher"
)

$isInstalled = $false
foreach ($path in $ubisoftPaths) {
    if (Test-Path $path) {
        $isInstalled = $true
        Write-Host "Ubisoft Connect found at: $path" -ForegroundColor Green
        break
    }
}

if (-not $isInstalled) {
    Write-Warning "Ubisoft Connect installation verification failed"
}

# 6. Install Tailscale
Write-Host "[6/6] Installing Tailscale..." -ForegroundColor Cyan
$tailscaleUrl = "https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe"
$tailscaleInstaller = "$env:TEMP\tailscale-setup.exe"

try {
    Invoke-WebRequest $tailscaleUrl -OutFile $tailscaleInstaller -ErrorAction Stop
    if (Test-Path $tailscaleInstaller) {
        Write-Host "Starting Tailscale installation..." -ForegroundColor Yellow
        Start-Process -FilePath $tailscaleInstaller -ArgumentList "/S" -Wait
        
        # Wait for installation to complete and start service
        Start-Sleep -Seconds 10
        
        # Try both possible installation paths
        $tailscalePaths = @(
            "C:\Program Files\Tailscale\tailscale.exe",
            "C:\Program Files (x86)\Tailscale IPN\tailscale.exe"
        )
        
        $tailscaleExe = $null
        foreach ($path in $tailscalePaths) {
            if (Test-Path $path) {
                $tailscaleExe = $path
                break
            }
        }
        
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

# 7. Install VDD Automatically
Write-Host "[7/6] Installing Virtual Display Driver (VDD) Automatically..." -ForegroundColor Cyan
$vddInstaller = "$env:TEMP\Virtual.Display.Driver-v24.12.24-setup-x64.exe"

try {
    Invoke-WebRequest "https://github.com/ULTRA-VAGREE/Virtual-Display-Driver-Compatibility-Fork/releases/download/v24.12.24/Virtual.Display.Driver-v24.12.24-setup-x64.exe" -OutFile $vddInstaller
    Start-Process -FilePath $vddInstaller -ArgumentList "/S" -Wait
    Write-Host "VDD installed successfully" -ForegroundColor Green
    
    # Copy config
    $vddCfg = Join-Path $PSScriptRoot "configs\vdd-settings.xml"
    Copy-Item $vddCfg -Destination "C:\ProgramData\VirtualDisplayDriver\vdd-settings.xml" -Force
    Write-Host "VDD settings configured" -ForegroundColor Green
} catch {
    Write-Warning "VDD automated install failed, please install manually"
    if (Test-Path $vddInstaller) {
        Start-Process -FilePath $vddInstaller
        Read-Host "Press Enter after manual VDD installation"
    }
    # Copy config
    $vddCfg = Join-Path $PSScriptRoot "configs\vdd-settings.xml"
    Copy-Item $vddCfg -Destination "C:\ProgramData\VirtualDisplayDriver\vdd-settings.xml" -Force
    Write-Host "VDD settings configured" -ForegroundColor Green
}

# 8. NVIDIA drivers
Write-Host "Installing NVIDIA drivers..." -ForegroundColor Cyan
if (Test-Path "$PSScriptRoot\nvidia.ps1") {
    & "$PSScriptRoot\nvidia.ps1"
} else {
    Write-Warning "nvidia.ps1 not found. Skipping NVIDIA driver installation."
}

Write-Host "=== VM Setup Complete! Reboot recommended. ===" -ForegroundColor Green
