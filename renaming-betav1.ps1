# Update .env with cert/key file paths based on file name patterns
# Usage: Run from the folder containing .env and generated cert files/keys
$mapping = @(
    @{ Pattern = "*provider_server*.pem"; Key = "FHIR_API_GATEWAY_HTTPS_CERTIFICATE"; Folder = "ssl" },
    @{ Pattern = "*provider_server*.key"; Key = "FHIR_API_GATEWAY_HTTPS_CERTIFICATE_PRIVATE_KEY"; Folder = "ssl" },
    @{ Pattern = "*provider_client*.pem"; Key = "REGIONAL_DATAPROVIDER_HTTPS_CLIENT_CERTIFICATE" ; Folder = "pix" },
    @{ Pattern = "*provider_client*.key"; Key = "REGIONAL_DATAPROVIDER_HTTPS_CLIENT_CERTIFICATE_KEY"; Folder = "pix" }
)

# Locate working directory
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Get-Location }

# Load .env
$envPath = Join-Path $scriptDir ".env"
if (-not (Test-Path $envPath)) {
    Write-Error ".env file not found at $envPath"
    exit 1
}

$envLines = Get-Content $envPath
$updatedLines = @()
$fileMatches = @{}

# Match files to .env keys
foreach ($entry in $mapping) {
    $file = Get-ChildItem -Path $scriptDir -Recurse -File -Filter ($entry.Pattern) | Select-Object -First 1
    if ($file) {
        $folder = $entry.Folder
        $fileMatches[$entry.key] = "file://./$folder/$($file.Name)"
        Write-Host "Found file for $($entry.Key): $($fileMatches[$entry.Key])"
    } else {
        Write-Warning "No match found for pattern: $($entry.Pattern)"
    }
}

foreach ($key in $fileMatches.Keys) {
    if (-not ($envLines -match "^\s*$key\s*=")) {
        Write-Warning "Key '$key' not found in .env — no update made for this entry."
    }
}


# Update or retain original .env lines
foreach ($line in $envLines) {
    $matched = $false
    foreach ($key in $fileMatches.Keys) {
        if ($line -match "^\s*$key\s*=") {
            $updatedLines += "$key=$($fileMatches[$key])"
            $matched = $true
            break
        }
    }
    if (-not $matched) {
        $updatedLines += $line
    }
}

Write-Host "`n🔄 Updated values:" -ForegroundColor Cyan
$fileMatches.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key) = $($_.Value)"
}
Write-Host "`.env updated successfully." -ForegroundColor Green
