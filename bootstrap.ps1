# bootstrap.ps1
$repoZip = "https://github.com/<YOUR-USER>/gaming-vm-setup/archive/refs/heads/main.zip"
$dest = "$env:TEMP\repo.zip"
$outDir = "$env:TEMP\my-setup"

Write-Host "Downloading setup repository..."
Invoke-WebRequest -Uri $repoZip -OutFile $dest

Write-Host "Extracting repository..."
Expand-Archive $dest -DestinationPath $outDir -Force
Remove-Item $dest

Write-Host "Running setup script..."
$setup = Get-ChildItem -Path $outDir -Recurse -Filter "setup.ps1" | Select-Object -First 1
& powershell -ExecutionPolicy Bypass -File $setup.FullName
