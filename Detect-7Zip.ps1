# Get latest 7-Zip version from web
try {
    $html = Invoke-WebRequest "https://www.7-zip.org/download.html" -UseBasicParsing
    if ($html.Content -match 'Download 7-Zip ([\d\.]+)') {
        $latest = $matches[1]
    } else {
        Write-Host "Could not extract version from HTML."
        exit 1
    }
} catch {
    Write-Host "Failed to fetch latest version."
    exit 1
}

# Normalize to major.minor format (e.g., 24.09)
$normalized = ($latest.Split('.')[0..1] -join '.')

# Search registry for installed 7-Zip versions
$regPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
)

$found = $false

foreach ($path in $regPaths) {
    $apps = Get-ItemProperty -Path "$path\*" -ErrorAction SilentlyContinue | Where-Object {
        $_.DisplayName -like "7-Zip*" -and $_.DisplayVersion -like "$normalized*"
    }
    if ($apps) {
        Write-Host "7-Zip version $normalized is installed."
        $found = $true
        break
    }
}

if ($found) {
    exit 0
} else {
    Write-Host "7-Zip is missing or outdated."
    exit 1
}
