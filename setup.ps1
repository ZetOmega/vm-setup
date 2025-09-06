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
try {
    winget install --id=Ubisoft.UbisoftConnect --silent --accept-source-agreements --accept-package-agreements
    Write-Host "Ubisoft Connect installed successfully" -ForegroundColor Green
} catch {
    Write-Warning "Ubisoft Connect installation failed: $($_.Exception.Message)"
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

# 7. Install VDD with Complete Automation
Write-Host "[7/6] Installing Virtual Display Driver (VDD)..." -ForegroundColor Cyan
$vddInstaller = "$env:TEMP\Virtual.Display.Driver-v24.12.24-setup-x64.exe"
$ahkScript = "$env:TEMP\vdd_install.ahk"

try {
    # Download VDD installer
    Write-Host "Downloading VDD installer..." -ForegroundColor Yellow
    Invoke-WebRequest "https://github.com/ULTRA-VAGREE/Virtual-Display-Driver-Compatibility-Fork/releases/download/v24.12.24/Virtual.Display.Driver-v24.12.24-setup-x64.exe" -OutFile $vddInstaller -ErrorAction Stop

    if (Test-Path $vddInstaller) {
        # Create AutoHotKey script for automated installation
        $ahkContent = @"
#NoEnv
SendMode Input
SetWorkingDir %A_ScriptDir%

; Run the installer
Run, $vddInstaller

; Wait for installer window
WinWait, Virtual Display Driver Setup,, 30
if ErrorLevel
{
    ExitApp 1
}

; Click Next button
WinActivate
ControlClick, Button2, Virtual Display Driver Setup  ; Next button

; Wait for license agreement
WinWait, Virtual Display Driver Setup,, 10
if ErrorLevel
{
    ExitApp 1
}

; Accept license and click Next
ControlClick, Button2, Virtual Display Driver Setup  ; I Agree
Sleep 500
ControlClick, Button3, Virtual Display Driver Setup  ; Next button

; Wait for installation page
WinWait, Virtual Display Driver Setup,, 10
if ErrorLevel
{
    ExitApp 1
}

; Click Install
ControlClick, Button3, Virtual Display Driver Setup  ; Install button

; Wait for completion (longer timeout)
WinWait, Virtual Display Driver Setup,, 60
if ErrorLevel
{
    ExitApp 1
}

; Click Finish
ControlClick, Button4, Virtual Display Driver Setup  ; Finish button

ExitApp 0
"@

        Set-Content -Path $ahkScript -Value $ahkContent

        # Download AutoHotKey if not installed
        $ahkPath = "C:\Program Files\AutoHotkey\AutoHotkey.exe"
        if (-not (Test-Path $ahkPath)) {
            Write-Host "Downloading AutoHotKey for automated installation..." -ForegroundColor Yellow
            $ahkInstaller = "$env:TEMP\AutoHotkey_Installer.exe"
            Invoke-WebRequest "https://www.autohotkey.com/download/ahk-install.exe" -OutFile $ahkInstaller
            Start-Process -FilePath $ahkInstaller -ArgumentList "/S" -Wait
        }

        # Run automated installation
        Write-Host "Running automated VDD installation..." -ForegroundColor Yellow
        Start-Process -FilePath $ahkPath -ArgumentList $ahkScript -Wait

        # Verify installation
        if (Test-Path "C:\ProgramData\VirtualDisplayDriver") {
            Write-Host "VDD installed successfully" -ForegroundColor Green
            
            # Copy configuration
            $vddCfg = Join-Path $PSScriptRoot "configs\vdd-settings.xml"
            if (Test-Path $vddCfg) {
                Copy-Item $vddCfg -Destination "C:\ProgramData\VirtualDisplayDriver\vdd-settings.xml" -Force
                Write-Host "VDD settings configured" -ForegroundColor Green
            }
        }

        # Cleanup
        Remove-Item $ahkScript -Force -ErrorAction SilentlyContinue
        if (Test-Path $vddInstaller) {
            Remove-Item $vddInstaller -Force -ErrorAction SilentlyContinue
        }
    }
} catch {
    Write-Warning "VDD automated installation failed: $($_.Exception.Message)"
    Write-Host "Falling back to manual installation..." -ForegroundColor Yellow
    
    # Fallback to manual with instructions
    if (Test-Path $vddInstaller) {
        Write-Host "Please install VDD manually. The installer is here: $vddInstaller" -ForegroundColor Yellow
        Write-Host "Steps: 1) Run installer 2) Click Next 3) Accept license 4) Click Install 5) Click Finish" -ForegroundColor Yellow
        Read-Host "Press Enter when VDD installation is complete"
    }
}

# 8. NVIDIA drivers
Write-Host "Installing NVIDIA drivers..." -ForegroundColor Cyan
if (Test-Path "$PSScriptRoot\nvidia.ps1") {
    & "$PSScriptRoot\nvidia.ps1"
} else {
    Write-Warning "nvidia.ps1 not found. Skipping NVIDIA driver installation."
}

Write-Host "=== VM Setup Complete! Reboot recommended. ===" -ForegroundColor Green
