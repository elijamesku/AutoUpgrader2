# Copies Install-7Zip.ps1, runs it immediately, then creates scheduled task to repeat every 14 days

$taskName = "7ZipAutoUpdater"
$taskDescription = "Automatically updates 7-Zip every 14 days."
$targetScriptPath = "C:\ProgramData\7ZipUpdater\Install-7Zip.ps1"
$sourceScript = "$PSScriptRoot\Source\Install-7Zip.ps1"

# Ensure ProgramData destination exists
$targetFolder = Split-Path -Path $targetScriptPath
if (-not (Test-Path $targetFolder)) {
    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
}

# Copy install script
if (-not (Test-Path $sourceScript)) {
    Write-Host "Source install script not found: $sourceScript"
    exit 1
}
Copy-Item -Path $sourceScript -Destination $targetScriptPath -Force

# Run the install script immediately
Write-Host "Running Install-7Zip.ps1 immediately..."
powershell.exe -ExecutionPolicy Bypass -File $targetScriptPath

# Setup scheduled task for 14-day repeat
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-ExecutionPolicy Bypass -File `"$targetScriptPath`""
$trigger = New-ScheduledTaskTrigger -Daily -DaysInterval 14 -At 3am
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -StartWhenAvailable

try {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue
} catch {}

Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -RunLevel Highest -User "SYSTEM"
Write-Host "Scheduled task '$taskName' created to run every 14 days at 3 AM."
