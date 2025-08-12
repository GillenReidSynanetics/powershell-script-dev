<#
.SYNOPSIS
Updates the .env file with certificate and key file paths based on file name patterns.

.DESCRIPTION
This script scans the current directory (and subdirectories) for certificate and key files matching specific patterns.
It then updates the corresponding environment variable entries in the .env file to reference the discovered files using a relative file URI.
A backup of the original .env file is created before any modifications.

.PARAMETER mapping
An array of hashtables specifying:
- Pattern: The file name pattern to search for.
- Key: The environment variable to update in .env.
- Folder: The folder to use in the file URI.

.NOTES
- Run this script from the folder containing the .env file and the generated certificate/key files.
- Only the first matching file for each pattern is used.
- If a key is not found in .env, a warning is issued and no update is made for that entry.
- The script creates a timestamped backup of the .env file before making changes.

.EXAMPLE
# Run the script in the directory containing .env and cert/key files
.\renaming-betav1.ps1

# This will update .env entries such as:
# FHIR_API_GATEWAY_HTTPS_CERTIFICATE=file://./ssl/provider_server.pem

#>


# Update .env with cert/key file paths based on file name patterns
# Usage: Run from the folder containing .env and generated cert files/keys
# Mapping is defind below, can be modified as needed

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

# Backup existing .env file
$timeStamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
$backupEnvPath = "$envPath.$timeStamp.bak"
Write-Host "Creating backup of .env at $backupEnvPath"
Copy-Item -Path $envPath -Destination $backupEnvPath -Force

# Read existing .env file
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
# Check if keys exist in .env and update or warn
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

# Write updated lines back to .env
Set-Content -Path $envPath -Value $updatedLines -Force
Write-Host "Valued Updated" -ForegroundColor Cyan
$fileMatches.GetEnumerator() | ForEach-Object {
    Write-Host "  $($_.Key) = $($_.Value)"
}
Write-Host "`.env updated successfully." -ForegroundColor Green
