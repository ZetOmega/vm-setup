# bootstrap.ps1
Write-Host "=== Starting VM Setup Bootstrap ===" -ForegroundColor Green

# Function to display menu and get user selection
function Show-Menu {
    param(
        [string]$Title,
        [array]$Options,
        [string]$Prompt = "Enter your choice",
        [bool]$AllowMultiple = $false
    )
    
    Write-Host "`n$Title" -ForegroundColor Cyan
    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "$($i+1). $($Options[$i])" -ForegroundColor Yellow
    }
    
    if ($AllowMultiple) {
        Write-Host "$($Options.Count+1). All" -ForegroundColor Yellow
        Write-Host "$($Options.Count+2). None" -ForegroundColor Yellow
    }
    
    while ($true) {
        $choice = Read-Host "`n$Prompt"
        
        if ($AllowMultiple) {
            if ($choice -eq ($Options.Count+1)) {
                return 1..$Options.Count
            }
            elseif ($choice -eq ($Options.Count+2)) {
                return @()
            }
            elseif ($choice -match '^(\d+)(,\s*\d+)*$') {
                $selections = $choice -split ',' | ForEach-Object { [int]::Parse($_.Trim()) }
                $valid = $selections | Where-Object { $_ -ge 1 -and $_ -le $Options.Count }
                if ($valid.Count -gt 0) {
                    return $valid
                }
            }
        }
        else {
            if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count) {
                return [int]$choice
            }
        }
        
        Write-Host "Invalid selection. Please try again." -ForegroundColor Red
    }
}

# Collect user choices
$streamingOptions = @("Sunshine (with Tailscale and VDD)", "Parsec", "Both", "None")
$streamingChoice = Show-Menu -Title "Select streaming solution:" -Options $streamingOptions

$launcherOptions = @("Steam", "Epic Games Launcher", "Ubisoft Connect")
$launcherChoices = Show-Menu -Title "Select game launchers to install:" -Options $launcherOptions -AllowMultiple $true

$driverChoice = Read-Host "`nDo you want to install NVIDIA drivers? (y/N)"
$installDrivers = ($driverChoice -eq 'y' -or $driverChoice -eq 'Y')

$hostname = Read-Host "`nEnter hostname for this VM"

if ($streamingChoice -eq 1 -or $streamingChoice -eq 3) {
    $env:TAILSCALE_KEY = Read-Host "Enter your Tailscale Auth Key"
}

# Set hostname
try {
    Rename-Computer -NewName $hostname -Force -PassThru
    Write-Host "Hostname set to: $hostname" -ForegroundColor Green
}
catch {
    Write-Warning "Failed to set hostname: $($_.Exception.Message)"
}

# Prepare temp folder
$tempDir = "$env:TEMP\vm-setup"
if (Test-Path $tempDir) { Remove-Item $tempDir -Recurse -Force }
New-Item -ItemType Directory -Path $tempDir | Out-Null

# Download repo ZIP
$repoZip = "$tempDir\vm-setup.zip"
Write-Host "Downloading vm-setup repo ZIP..." -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri "https://github.com/ZetOmega/vm-setup/archive/refs/heads/main.zip" -OutFile $repoZip -ErrorAction Stop
}
catch {
    Write-Warning "Failed to download repo: $($_.Exception.Message)"
    exit 1
}

# Unzip
Write-Host "Extracting repo..." -ForegroundColor Cyan
try {
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::ExtractToDirectory($repoZip, $tempDir)
}
catch {
    Write-Warning "Failed to extract repo with .NET method: $($_.Exception.Message)"
    # Fallback to PowerShell extraction
    try {
        Expand-Archive -Path $repoZip -DestinationPath $tempDir -Force
    }
    catch {
        Write-Error "Failed to extract repo: $($_.Exception.Message)"
        exit 1
    }
}

# Setup folder
$setupFolder = Join-Path $tempDir "vm-setup-main"

# Set environment variables for the setup script
$env:INSTALL_SUNSHINE = ($streamingChoice -eq 1 -or $streamingChoice -eq 3)
$env:INSTALL_PARSEC = ($streamingChoice -eq 2 -or $streamingChoice -eq 3)
$env:INSTALL_STEAM = ($launcherChoices -contains 1)
$env:INSTALL_EPIC = ($launcherChoices -contains 2)
$env:INSTALL_UBISOFT = ($launcherChoices -contains 3)
$env:INSTALL_NVIDIA = $installDrivers

# Call setup.ps1
Write-Host "`n=== Starting Installation Process ===" -ForegroundColor Green
if (Test-Path "$setupFolder\setup.ps1") {
    & "$setupFolder\setup.ps1"
}
else {
    Write-Error "setup.ps1 not found in extracted files"
    exit 1
}

Write-Host "`n=== Setup Complete! ===" -ForegroundColor Green
if ($streamingChoice -eq 1 -or $streamingChoice -eq 3) {
    Write-Host "Please complete VDD installation if prompted and configure Sunshine." -ForegroundColor Yellow
}
Write-Host "Reboot recommended." -ForegroundColor Yellow
