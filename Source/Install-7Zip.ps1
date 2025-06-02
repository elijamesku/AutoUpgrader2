# Step 1: Get the latest version from 7-Zip website
try {
    $html = Invoke-WebRequest "https://www.7-zip.org/download.html" -UseBasicParsing
    $html.Content -match 'Download 7-Zip ([\d\.]+)' | Out-Null
    $latest = $matches[1]
    Write-Host "Latest 7-Zip version: $latest"
} catch {
    Write-Host "Failed to retrieve latest version."
    exit 1
}

# Step 2: Uninstall existing version using native uninstaller
$sevenZipPath = "C:\Program Files\7-Zip"
$uninstaller = Join-Path $sevenZipPath "Uninstall.exe"

if (Test-Path $uninstaller) {
    Write-Host "Uninstalling existing 7-Zip..."
    Start-Process $uninstaller -ArgumentList "/S" -Wait
    Start-Sleep -Seconds 3
}

# Step 3: Remove leftover folder
if (Test-Path $sevenZipPath) {
    Write-Host "Cleaning up leftover folder..."
    Remove-Item -Path $sevenZipPath -Recurse -Force -ErrorAction SilentlyContinue
}

# Step 4: Download new MSI
$msiFile = "7z$($latest.Replace('.', ''))-x64.msi"
$downloadUrl = "https://www.7-zip.org/a/$msiFile"
$installerPath = "$env:TEMP\$msiFile"

try {
    Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath -UseBasicParsing
} catch {
    Write-Host "Download failed."
    exit 1
}

# Step 5: Install new version
Write-Host "Installing $msiFile..."
Start-Process "msiexec.exe" -ArgumentList "/i `"$installerPath`" /qn /norestart" -Wait

# Step 6: Cleanup
Remove-Item $installerPath -Force -ErrorAction SilentlyContinue
Write-Host "7-Zip $latest installed successfully."
