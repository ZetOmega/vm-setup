# This script is designed to install the bare essential Nvidia drivers
param (
    [switch]$clean = $false,
    [string]$folder = "$env:temp"
)

# Checking currently installed driver version
Write-Host "Attempting to detect currently installed driver version..."
try {
    $VideoController = Get-WmiObject -ClassName Win32_VideoController | Where-Object { $_.Name -match "NVIDIA" }
    if (-not $VideoController) {
        throw "No NVIDIA device found"
    }
    $ins_version = ($VideoController.DriverVersion.Replace('.', '')[-5..-1] -join '').insert(3, '.')
    Write-Host "Installed version `t$ins_version"
}
catch {
    Write-Host -ForegroundColor Yellow "Unable to detect a compatible Nvidia device: $($_.Exception.Message)"
    Write-Host "Press any key to exit..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Checking latest driver version
$uri = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php' +
'?func=DriverManualLookup' +
'&psid=120' +
'&pfid=929' +
'&osID=57' +
'&languageCode=1033' +
'&isWHQL=1' +
'&dch=1' +
'&sort1=0' +
'&numberOfResults=1'

try {
    $response = Invoke-WebRequest -Uri $uri -Method GET -UseBasicParsing
    $payload = $response.Content | ConvertFrom-Json
    $version = $payload.IDS[0].downloadInfo.Version
    Write-Host "Latest version `t`t$version"
}
catch {
    Write-Error "Failed to get latest driver version: $($_.Exception.Message)"
    exit 1
}

# Comparing versions
if (!$clean -and ($version -eq $ins_version)) {
    Write-Host "The installed version is the same as the latest version."
    Write-Host "Press any key to exit..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Create temp folder
$nvidiaTempFolder = "$folder\NVIDIA"
New-Item -Path $nvidiaTempFolder -ItemType Directory -Force | Out-Null

# Generating download link
if ([Environment]::OSVersion.Version -ge (new-object 'Version' 9, 1)) {
    $windowsVersion = "win10-win11"
} else {
    $windowsVersion = "win8-win7"
}

$windowsArchitecture = if ([Environment]::Is64BitOperatingSystem) { "64bit" } else { "32bit" }

$url = "https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql.exe"
$rp_url = "https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql-rp.exe"

# -----------------------------
# Downloading driver (no progress)
# -----------------------------
$dlFile = "$nvidiaTempFolder\$version.exe"
Write-Host "Downloading the latest version to $dlFile"
try {
    Invoke-WebRequest -Uri $url -OutFile $dlFile -ErrorAction Stop
    Write-Host "Download completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Download failed, trying alternative RP package..." -ForegroundColor Yellow
    try {
        Invoke-WebRequest -Uri $rp_url -OutFile $dlFile -ErrorAction Stop
        Write-Host "Download completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Both download attempts failed: $($_.Exception.Message)"
        exit 1
    }
}

# -----------------------------
# Extract using NVIDIA native /extract
# -----------------------------
$extractFolder = "$nvidiaTempFolder\$version"
Write-Host "Extracting files..."
try {
    Start-Process -FilePath $dlFile -ArgumentList "/extract:$extractFolder /quiet" -Wait
    Write-Host "Extraction completed successfully" -ForegroundColor Green
}
catch {
    Write-Error "Extraction failed: $($_.Exception.Message)"
    exit 1
}

# Remove unneeded dependencies from setup.cfg
if (Test-Path "$extractFolder\setup.cfg") {
    try {
        (Get-Content "$extractFolder\setup.cfg") | Where-Object { $_ -notmatch 'name="\${{(EulaHtmlFile|FunctionalConsentFile|PrivacyPolicyFile)}}' } | Set-Content "$extractFolder\setup.cfg" -Encoding UTF8 -Force
    }
    catch {
        Write-Warning "Failed to modify setup.cfg: $($_.Exception.Message)"
    }
}

# Installing drivers with GUI progress
Write-Host "Installing Nvidia drivers now..."
$install_args = "-s" # GUI visible progress
if ($clean) {
    $install_args += " -clean"
}

if (Test-Path "$extractFolder\setup.exe") {
    try {
        Start-Process -FilePath "$extractFolder\setup.exe" -ArgumentList $install_args -Wait
        Write-Host "Driver installation completed" -ForegroundColor Green
    }
    catch {
        Write-Error "Driver installation failed: $($_.Exception.Message)"
    }
} else {
    Write-Error "setup.exe not found in extracted files"
}

# Cleanup
Write-Host "Cleaning up downloaded files..."
Remove-Item $nvidiaTempFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host -ForegroundColor Green "Driver installed. You may need to reboot to finish installation."
Write-Host "Script completed. Exiting..."
