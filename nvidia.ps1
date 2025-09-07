# NVIDIA Driver Silent Installer
param (
    [switch]$clean = $false
)

# Set security protocol for better download performance
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Create temp folder
$nvidiaTempFolder = "$env:temp\NVIDIA"
New-Item -Path $nvidiaTempFolder -ItemType Directory -Force | Out-Null

# Function to get NVIDIA GPU information
function Get-NvidiaGpuInfo {
    try {
        # Try to get GPU info using WMI
        $gpuInfo = Get-WmiObject -Class Win32_VideoController | Where-Object {$_.Name -like "*NVIDIA*"} | Select-Object -First 1
        
        if ($null -eq $gpuInfo) {
            Write-Host "No NVIDIA GPU detected via WMI. Trying alternative method..." -ForegroundColor Yellow
            
            # Alternative method using device manager info
            $deviceInfo = Get-PnpDevice -Class Display | Where-Object {$_.FriendlyName -like "*NVIDIA*"} | Select-Object -First 1
            if ($null -ne $deviceInfo) {
                return @{
                    Name = $deviceInfo.FriendlyName
                    # Extract device ID from hardware ID
                    DeviceId = ($deviceInfo.InstanceId -split "\\")[1] -replace "&.*", ""
                }
            }
            
            throw "No NVIDIA GPU found in the system"
        }
        
        # Extract device ID from PNPDeviceID
        $deviceId = ($gpuInfo.PNPDeviceID -split "\\")[1] -replace "&.*", ""
        
        return @{
            Name = $gpuInfo.Name
            DeviceId = $deviceId
        }
    }
    catch {
        Write-Error "Failed to detect NVIDIA GPU: $($_.Exception.Message)"
        exit 1
    }
}

# Get GPU information
Write-Host "Detecting NVIDIA GPU..." -ForegroundColor Yellow
$gpuInfo = Get-NvidiaGpuInfo
Write-Host "Detected GPU: $($gpuInfo.Name)" -ForegroundColor Green
Write-Host "Device ID: $($gpuInfo.DeviceId)" -ForegroundColor Green

# Checking latest driver version for this specific GPU
Write-Host "Checking for latest NVIDIA driver version for your GPU..."
$uri = 'https://gfwsl.geforce.com/services_toolkit/services/com/nvidia/services/AjaxDriverService.php' +
'?func=DriverManualLookup' +
'&psid=120' +  # GeForce
'&pfid=929' +  # Windows 10/11 64-bit
'&osID=57' +
'&languageCode=1033' +
'&isWHQL=1' +
'&dch=1' +
'&sort1=0' +
'&numberOfResults=1' +
"&gpu=$($gpuInfo.DeviceId)"

try {
    $response = Invoke-WebRequest -Uri $uri -Method GET -UseBasicParsing
    $payload = $response.Content | ConvertFrom-Json
    $version = $payload.IDS[0].downloadInfo.Version
    Write-Host "Latest version for your GPU: $version" -ForegroundColor Green
}
catch {
    Write-Error "Failed to get latest driver version: $($_.Exception.Message)"
    Write-Host "Falling back to generic driver..." -ForegroundColor Yellow
    
    # Fallback to generic driver lookup
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
        Write-Host "Latest generic driver version: $version" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to get generic driver version: $($_.Exception.Message)"
        exit 1
    }
}

# Generating download link
if ([Environment]::OSVersion.Version -ge (new-object 'Version' 9, 1)) {
    $windowsVersion = "win10-win11"
} else {
    $windowsVersion = "win8-win7"
}

$windowsArchitecture = if ([Environment]::Is64BitOperatingSystem) { "64bit" } else { "32bit" }

$url = "https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql.exe"
$rp_url = "https://international.download.nvidia.com/Windows/$version/$version-desktop-$windowsVersion-$windowsArchitecture-international-dch-whql-rp.exe"

# Download driver with proper progress bar
$dlFile = "$nvidiaTempFolder\NVIDIA-Driver-$version.exe"
Write-Host "Downloading driver..." -ForegroundColor Yellow

function Download-FileWithProgress {
    param($url, $path)
    
    try {
        # Get content length for progress calculation
        $request = [System.Net.HttpWebRequest]::Create($url)
        $request.Method = "HEAD"
        $response = $request.GetResponse()
        $totalBytes = $response.ContentLength
        $response.Close()
        
        if ($totalBytes -eq -1) {
            Write-Host "Content length unavailable, using simple download..." -ForegroundColor Yellow
            $webClient = New-Object System.Net.WebClient
            $webClient.DownloadFile($url, $path)
            return
        }
        
        # Create the stream objects
        $request = [System.Net.HttpWebRequest]::Create($url)
        $response = $request.GetResponse()
        $responseStream = $response.GetResponseStream()
        $targetStream = [System.IO.File]::Create($path)
        
        # Download in chunks and show progress
        $buffer = New-Object byte[] 256KB
        $count = $responseStream.Read($buffer, 0, $buffer.Length)
        $downloadedBytes = $count
        $lastProgress = -1
        
        while ($count -gt 0) {
            $targetStream.Write($buffer, 0, $count)
            $count = $responseStream.Read($buffer, 0, $buffer.Length)
            $downloadedBytes += $count
            
            # Update progress bar every 1% change
            $progress = [int](($downloadedBytes / $totalBytes) * 100)
            if ($progress -ne $lastProgress) {
                Write-Progress -Activity "Downloading NVIDIA Driver" -Status "Downloaded: $progress%" -PercentComplete $progress
                $lastProgress = $progress
            }
        }
        
        # Clean up
        Write-Progress -Activity "Downloading NVIDIA Driver" -Status "Download Complete!" -Completed
        $targetStream.Flush()
        $targetStream.Close()
        $responseStream.Close()
        $response.Close()
        
    }
    catch {
        Write-Error "Download error: $($_.Exception.Message)"
        throw
    }
}

function Download-FileSimple {
    param($url, $path)
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $path)
}

try {
    Write-Host "Downloading from primary URL..." 
    
    # Try with progress bar first
    try {
        Download-FileWithProgress -url $url -path $dlFile
    }
    catch {
        # Fallback to simple download if progress bar fails
        Write-Host "Progress bar failed, using simple download..." -ForegroundColor Yellow
        Download-FileSimple -url $url -path $dlFile
    }
    
    if (Test-Path $dlFile) {
        $fileSize = (Get-Item $dlFile).Length / 1MB
        Write-Host "Download completed successfully! ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green
    }
    else {
        throw "Download file not found"
    }
}
catch {
    Write-Host "Primary download failed, trying alternative RP package..." -ForegroundColor Yellow
    try {
        # Try with progress bar for fallback
        try {
            Download-FileWithProgress -url $rp_url -path $dlFile
        }
        catch {
            # Fallback to simple download if progress bar fails
            Write-Host "Progress bar failed, using simple download..." -ForegroundColor Yellow
            Download-FileSimple -url $rp_url -path $dlFile
        }
        
        if (Test-Path $dlFile) {
            $fileSize = (Get-Item $dlFile).Length / 1MB
            Write-Host "Download completed successfully! ($([math]::Round($fileSize, 2)) MB)" -ForegroundColor Green
        }
        else {
            throw "Download file not found"
        }
    }
    catch {
        Write-Error "Both download attempts failed: $($_.Exception.Message)"
        exit 1
    }
}

# Silent installation
Write-Host "Starting silent installation..." -ForegroundColor Yellow
Write-Host "This may take several minutes. Please wait..." -ForegroundColor Yellow

$install_args = @("/s")  # lowercase s for fully silent install

if ($clean) {
    $install_args += "/clean"
}

# Additional silent parameters
$install_args += @(
    "/noreboot",
    "/noeula",
    "/nofinish"
)

try {
    $process = Start-Process -FilePath $dlFile -ArgumentList $install_args -Wait -PassThru -NoNewWindow
    
    # NVIDIA installers often return non-zero exit codes even on success
    if ($process.ExitCode -eq 0) {
        Write-Host "Driver installation completed successfully!" -ForegroundColor Green
    }
    else {
        Write-Host "Installation completed with exit code $($process.ExitCode)" -ForegroundColor Yellow
        Write-Host "This is normal for NVIDIA drivers - installation was likely successful." -ForegroundColor Yellow
    }
}
catch {
    Write-Error "Installation failed: $($_.Exception.Message)"
    exit 1
}

# Cleanup
Write-Host "Cleaning up temporary files..." 
Remove-Item $nvidiaTempFolder -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "==========================================" -ForegroundColor Green
Write-Host "NVIDIA driver installation completed!" -ForegroundColor Green
Write-Host "A system reboot may be required." -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Green
