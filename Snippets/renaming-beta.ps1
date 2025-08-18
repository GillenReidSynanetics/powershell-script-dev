# Update .env with cert/key file paths based on file name patterns
# Usage: Run from the folder containing .env and generated cert files/keys
$mapping = @(
    @{ Pattern = "*provider_server*.pem"; Key = "FHIR_API_GATEWAY_HTTPS_CERTIFICATE" },
    @{ Pattern = "*provider_server*.key"; Key = "FHIR_API_GATEWAY_HTTPS_CERTIFICATE_PRIVATE_KEY" },
    @{ Pattern = "*provider_client*.pem"; Key = "REGIONAL_DATAPROVIDER_HTTPS_CLIENT_CERTIFICATE" },
    @{ Pattern = "*provider_client*.key"; Key = "REGIONAL_DATAPROVIDER_HTTPS_CLIENT_CERTIFICATE_KEY" }
)

# Locate working directory
$scriptDir = $PSScriptRoot
if (-not $scriptDir) { $scriptDir = Get-Location }

# Load .env
$envPath = Join-Path $scriptDir ".env"
if (-not (Test-Path $envPath)) {
    Write-Error "❌ .env file not found at $envPath"
    exit 1
}

$envLines = Get-Content $envPath
$updatedLines = @()
$fileMatches = @{}

# Match files to .env keys
foreach ($entry in $mapping) {
    $file = Get-ChildItem -Path $scriptDir -Recurse -File -Filter ($entry.Pattern) | Select-Object -First 1
    if ($file) {
        $relPath = [IO.Path]::GetRelativePath($scriptDir, $file.FullName).Replace("\", "/")
        $fileMatches[$entry.Key] = "file://./$relPath"
        Write-Host "✅ Matched $($entry.Pattern) → $entry.Key → $relPath"
    } else {
        Write-Warning "⚠️ No match found for pattern: $($entry.Pattern)"
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

# Append any missing keys
foreach ($key in $fileMatches.Keys) {
    if (-not ($updatedLines -match "^\s*$key\s*=")) {
        $updatedLines += "$key=$($fileMatches[$key])"
        Write-Host "➕ Added $key"
    }
}

# Write final .env
$updatedLines | Set-Content -Path $envPath
Write-Host "`n✅ .env updated successfully." -ForegroundColor Green
