# This script is designed to install the bare essential Nvidia drivers
param (
    [switch]$clean = $false,
    [string]$folder = "$env:temp",
    [switch]$silent = $false
)

# Set security protocol for better download performance
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

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
# Downloading driver with better performance
# -----------------------------
$dlFile = "$nvidiaTempFolder\$version.exe"
Write-Host "Downloading the latest version to $dlFile"

# Use faster download method with progress
function Download-File {
    param($url, $path)
    
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $path)
}

try {
    Write-Host "Downloading from primary URL..." -ForegroundColor Yellow
    Download-File -url $url -path $dlFile
    Write-Host "Download completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Primary download failed, trying alternative RP package..." -ForegroundColor Yellow
    try {
        Download-File -url $rp_url -path $dlFile
        Write-Host "Download completed successfully" -ForegroundColor Green
    }
    catch {
        Write-Error "Both download attempts failed: $($_.Exception.Message)"
        exit 1
    }
}

# -----------------------------
# Extract using NVIDIA native /extract with proper arguments
# -----------------------------
$extractFolder = "$nvidiaTempFolder\$version"
Write-Host "Extracting files..."
try {
    $extractArgs = "/s /extract=`"$extractFolder`""
    $process = Start-Process -FilePath $dlFile -ArgumentList $extractArgs -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -ne 0) {
        throw "Extraction failed with exit code $($process.ExitCode)"
    }
    
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
        Write-Host "Modified setup.cfg to skip EULA and consent dialogs" -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to modify setup.cfg: $($_.Exception.Message)"
    }
}

# Create response file for silent installation
$responseFile = "$extractFolder\nvidia_install.ini"
@"
[Options]
ProcessorType=Intel
EULA=1
DriverPackages=Display.Driver,Display.Optimus,PhysX,HDMI,3DVision,3DVisionUSB,GFExperience,NVI2,Display.Update,Ansel,Backend.Vulkan,Backend.Vulkan.Core,Backend.Vulkan.GL,Backend.Vulkan.VK,Backend.Vulkan.VK_LAYER,Backend.Vulkan.VK_LAYER_32,Backend.Vulkan.VK_LAYER_64,Backend.Vulkan.VK_LAYER_NV_optimus,Backend.Vulkan.VK_LAYER_VALVE,Backend.Vulkan.VK_LAYER_LUNARG,Backend.Vulkan.VK_LAYER_RENDERDOC,Backend.Vulkan.VK_LAYER_OCULUS,Backend.Vulkan.VK_LAYER_STEAM,Backend.Vulkan.VK_LAYER_STEAM_32,Backend.Vulkan.VK_LAYER_STEAM_64,Backend.Vulkan.VK_LAYER_API,Backend.Vulkan.VK_LAYER_API_32,Backend.Vulkan.VK_LAYER_API_64,Backend.Vulkan.VK_LAYER_GFE,Backend.Vulkan.VK_LAYER_GFE_32,Backend.Vulkan.VK_LAYER_GFE_64,Backend.Vulkan.VK_LAYER_NV,Backend.Vulkan.VK_LAYER_NV_32,Backend.Vulkan.VK_LAYER_NV_64,Backend.Vulkan.VK_LAYER_AMD,Backend.Vulkan.VK_LAYER_AMD_32,Backend.Vulkan.VK_LAYER_AMD_64,Backend.Vulkan.VK_LAYER_IMG,Backend.Vulkan.VK_LAYER_IMG_32,Backend.Vulkan.VK_LAYER_IMG_64,Backend.Vulkan.VK_LAYER_KHR,Backend.Vulkan.VK_LAYER_KHR_32,Backend.Vulkan.VK_LAYER_KHR_64,Backend.Vulkan.VK_LAYER_LUNARG_32,Backend.Vulkan.VK_LAYER_LUNARG_64,Backend.Vulkan.VK_LAYER_RENDERDOC_32,Backend.Vulkan.VK_LAYER_RENDERDOC_64,Backend.Vulkan.VK_LAYER_VALVE_32,Backend.Vulkan.VK_LAYER_VALVE_64,Backend.Vulkan.VK_LAYER_OCULUS_32,Backend.Vulkan.VK_LAYER_OCULUS_64,Backend.Vulkan.VK_LAYER_STEAM_OVERLAY,Backend.Vulkan.VK_LAYER_STEAM_OVERLAY_32,Backend.Vulkan.VK_LAYER_STEAM_OVERLAY_64,Backend.Vulkan.VK_LAYER_API_OVERLAY,Backend.Vulkan.VK_LAYER_API_OVERLAY_32,Backend.Vulkan.VK_LAYER_API_OVERLAY_64,Backend.Vulkan.VK_LAYER_GFE_OVERLAY,Backend.Vulkan.VK_LAYER_GFE_OVERLAY_32,Backend.Vulkan.VK_LAYER_GFE_OVERLAY_64,Backend.Vulkan.VK_LAYER_NV_OVERLAY,Backend.Vulkan.VK_LAYER_NV_OVERLAY_32,Backend.Vulkan.VK_LAYER_NV_OVERLAY_64,Backend.Vulkan.VK_LAYER_AMD_OVERLAY,Backend.Vulkan.VK_LAYER_AMD_OVERLAY_32,Backend.Vulkan.VK_LAYER_AMD_OVERLAY_64,Backend.Vulkan.VK_LAYER_IMG_OVERLAY,Backend.Vulkan.VK_LAYER_IMG_OVERLAY_32,Backend.Vulkan.VK_LAYER_IMG_OVERLAY_64,Backend.Vulkan.VK_LAYER_KHR_OVERLAY,Backend.Vulkan.VK_LAYER_KHR_OVERLAY_32,Backend.Vulkan.VK_LAYER_KHR_OVERLAY_64
CleanInstall=$($clean.ToString().ToLower())
NoWebsite=1
NoReboot=1
"@ | Set-Content -Path $responseFile -Encoding UTF8

# Installing drivers silently
Write-Host "Installing Nvidia drivers silently..."
$install_args = @(
    "-passive",
    "-noreboot",
    "-noeula",
    "-nofinish",
    "-s",
    "responsefile=`"$responseFile`""
)

if (Test-Path "$extractFolder\setup.exe") {
    try {
        $process = Start-Process -FilePath "$extractFolder\setup.exe" -ArgumentList $install_args -Wait -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host "Driver installation completed successfully" -ForegroundColor Green
        } else {
            Write-Warning "Driver installation completed with exit code $($process.ExitCode)"
        }
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
if (-not $silent) {
    Write-Host "Press any key to exit..."
    $host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
Write-Host "Script completed."
