# 7-Zip Auto-Updater for Intune

This sequence automates the installation and periodic updating of 7-Zip on Windows machines using Microsoft Intune. It ensures that 7-Zip is always up to date by:

- Uninstalling any existing version of 7-Zip.
- Downloading and installing the latest version from the official website.
- Setting up a scheduled task to check for updates every 14 days.


## Getting Started

### Prerequisites

- Windows 10 or later.
- Microsoft Intune environment.
- [IntuneWinAppUtil.exe](https://learn.microsoft.com/en-us/intune/intune-service/apps/apps-win32-prepare) for packaging the application.

## Info

This PowerShell-based setup will:
- Detect if the latest version of 7-Zip is installed.
- If not, uninstall the existing version, install the latest.
- Set a Scheduled Task to auto-check every 14 days.
- Be packaged and deployed through Intune using Win32App.

---

## Folder Structure

```
SevenZipAutoWin32/
├── Source/
│   └── Install-7Zip.ps1
├── Setup-ScheduledUpdater.ps1
├── Detect-7Zip.ps1
├── Output/  # (Generated by IntuneWinAppUtil.exe)
```

---

## Step-by-Step PowerShell Instructions

### 1. Set up the script files

**Install-7Zip.ps1 (in `Source/`)**
```powershell
This script performs the primary tasks:
1. Dynamically scrapes the latest 7-Zip version from the official website.
2. Uninstalls any currently installed version of 7-Zip.
3. Downloads the appropriate MSI installer.
4. Installs the application silently.
5. Cleans up after itself.

# Step 1: Get latest version
try {
    $html = Invoke-WebRequest "https://www.7-zip.org/download.html" -UseBasicParsing
    $html.Content -match 'Download 7-Zip ([\d\.]+)' | Out-Null
    $latest = $matches[1]
    Write-Host "Latest 7-Zip version: $latest"
} catch {
    Write-Host "Failed to retrieve latest version."
    exit 1
}

# Step 2: Uninstall old version
$sevenZipFolder = "C:\Program Files\7-Zip"
$uninstaller = Join-Path $sevenZipFolder "Uninstall.exe"
if (Test-Path $uninstaller) {
    Write-Host "Uninstalling..."
    Start-Process $uninstaller -ArgumentList "/S" -Wait
    Start-Sleep -Seconds 3
}

# Step 3: Clean folder
if (Test-Path $sevenZipFolder) {
    Remove-Item -Path $sevenZipFolder -Recurse -Force -ErrorAction SilentlyContinue
}

# Step 4: Download & Install
$msi = "7z$($latest.Replace('.', ''))-x64.msi"
$url = "https://www.7-zip.org/a/$msi"
$path = "$env:TEMP\$msi"
try {
    Invoke-WebRequest -Uri $url -OutFile $path -UseBasicParsing
} catch {
    Write-Host "Download failed"
    exit 1
}
Start-Process "msiexec.exe" -ArgumentList "/i `"$path`" /qn /norestart" -Wait
Remove-Item $path -Force
Write-Host "7-Zip $latest installed."
```

**Setup-ScheduledUpdater.ps1** 

```powershell
 This script does the following:
- Copies the `Install-7Zip.ps1` into a centralized and secured system location
- Registers a Windows Task Scheduler task that runs every 14 days as SYSTEM

$taskName = "7ZipAutoUpdater"
$target = "C:\ProgramData\7ZipUpdater\Install-7Zip.ps1"
$source = "$PSScriptRoot\Source\Install-7Zip.ps1"

if (-not (Test-Path (Split-Path $target))) {
    New-Item -Path (Split-Path $target) -ItemType Directory -Force
}
Copy-Item -Path $source -Destination $target -Force

$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$target`""
$trigger = New-ScheduledTaskTrigger -Daily -DaysInterval 14 -At 3am
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable

try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
} catch {}

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "SYSTEM"
Write-Host "Scheduled task '$taskName' created."
```

**Detect-7ZipVersion.ps1**
```powershell
This PowerShell script dynamically checks whether the latest version of 7-Zip is installed. If not, Intune flags the device as needing installation.

try {
    $html = Invoke-WebRequest "https://www.7-zip.org/download.html" -UseBasicParsing
    if ($html.Content -match 'Download 7-Zip ([\d\.]+)') {
        $latest = $matches[1]
    } else {
        Write-Host "Could not extract version."
        exit 1
    }
} catch {
    Write-Host "Failed to contact 7-Zip.org"
    exit 1
}

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$found = $false
foreach ($path in $regPaths) {
    $installed = Get-ItemProperty -Path "$path\*" -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "7-Zip*" -and $_.DisplayVersion -like "$latest*"
    }
    if ($installed) {
        $found = $true
        break
    }
}

if ($found) { exit 0 } else { exit 1 }
```

---

## Package into .intunewin File

**Run this in PowerShell**
```powershell
cd C:\tools
./IntuneWinAppUtil.exe -c "C:\SevenZipAutoWin32" -s "Setup-ScheduledUpdater.ps1" -o "C:\SevenZipAutoWin32\Output"
```

---

## Intune Configuration

1. Go to Intune Admin Center → Apps → Windows → Add → App Type: Win32
2. Upload your `.intunewin` file from `Output/`
3. **Install Command:**
```powershell
powershell.exe -ExecutionPolicy Bypass -File Setup-ScheduledUpdater.ps1
```
4. **Uninstall Command:**
```powershell
schtasks /Delete /TN "7ZipAutoUpdater" /F
```
5. **Detection Script:** (Add as custom detection script in Intune same from above)
```powershell
try {
    $html = Invoke-WebRequest "https://www.7-zip.org/download.html" -UseBasicParsing
    if ($html.Content -match 'Download 7-Zip ([\d\.]+)') {
        $latest = $matches[1]
    } else {
        exit 1
    }
} catch {
    exit 1
}

$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$found = $false
foreach ($path in $regPaths) {
    $installed = Get-ItemProperty -Path "$path\*" -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "7-Zip*" -and $_.DisplayVersion -like "$latest*"
    }
    if ($installed) {
        $found = $true
        break
    }
}

if ($found) { exit 0 } else { exit 1 }
```
## Commands to verify in powershell
**View task existence**
```
Get-ScheduledTask -TaskName "7ZipAutoUpdater"
```
**View trigger settings**
```
(Get-ScheduledTask -TaskName "7ZipAutoUpdater").triggers
```
**Confirm when it last ran and next run**
```
Get-ScheduledTaskInfo -TaskName "7ZipAutoUpdater"
```
**Force test the scheduler**
```
Start-ScheduledTask -TaskName "7ZipAutoUpdater"
```
---

## Summary *again
- Detects if latest version of 7-Zip is installed
- If outdated or missing, installs the newest one
- Creates a scheduled task that checks & updates silently every 14 days
- Deployable through Intune using Win32 format


