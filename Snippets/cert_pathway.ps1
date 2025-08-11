<#
.SYNOPSIS
    Script to validate and backup SSL certificate files mentioned in a .env file.

.DESCRIPTION
    This script reads a .env file for file paths, checks if the files exist, creates backups, and validates SSL certificate expiry dates.
    It supports .pem and .crt certificate files and skips .key files.

.PARAMETERS
    None

.NOTES
    - The script expects the .env file to be in the same directory as the script.
    - The script creates a backup of the files in a 'backups' directory within the script's directory.
    - The script generates a report in JSON format and saves it as 'report.json' in the script's directory.

.EXAMPLE
    .\cert-pathway.ps1
    Runs the script and performs the validation and backup operations.

#>

# --- 1. SETUP ---
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFilePath = Join-Path -Path $scriptDirectory -ChildPath ".env"
$backupDirectory = Join-Path -Path $scriptDirectory -ChildPath "backups"
$dateSuffix = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFilePath = Join-Path -path $scriptDirectory -ChildPath "report.json"
$report = @()

# --- 2. INITIAL CHECKS ---
# Check if .env file exists
if (-not (Test-Path -Path $envFilePath)) {
    Write-Error "File not found: $envFilePath"
    exit 1
}

# Create the main backup directory if it doesn't exist
if (-not (Test-Path -Path $backupDirectory)) {
    New-Item -Path $backupDirectory -ItemType Directory | Out-Null
    Write-Host "Created backup directory at $backupDirectory"
}

# --- 3. PARSE .ENV FILE ---
# Get all lines with what looks like a file path
$envVariables = Get-Content $envFilePath | Where-Object { $_ -match "=" }
$potentialPaths = @()
foreach ($line in $envVariables) {
    if ($line -match "=(file://|/.+|\\.+)") {
        $key, $value = $line -split "=", 2
        $value = $value.Trim('"', "'")
        $potentialPaths += [PSCustomObject]@{
            Key   = $key
            Value = $value -replace "file://", ""
        }
    }
}

# Check if any paths were found
if ($potentialPaths.Count -eq 0) {
    Write-Host "No file paths found in the .env file."
    exit 0
}

# --- 4. PROCESS EACH FILE PATH ---
Write-Host "`nStarting file processing and validation..."
foreach ($path in $potentialPaths) {
    # Create a result object for the report at the start of each loop
    $resultObject = [PSCustomObject]@{
        Key        = $path.Key
        FilePath   = $path.Value
        Exists     = $false
        Status     = "Not Processed"
        ExpiryDate = $null
        BackupPath = ""
    }

    if (Test-Path -Path $path.Value) {
        $resultObject.Exists = $true
        Write-Host "Path for '$($path.Key)' exists: $($path.Value)"

        # Backup Logic
        $backupSubDirectory = Join-Path -Path $backupDirectory -ChildPath (Split-Path -Parent $path.Value)
        $backupFilePath = Join-Path -Path $backupSubDirectory -ChildPath ("$(Split-Path $path.Value -Leaf)-$dateSuffix")
        if (-not (Test-Path -Path $backupSubDirectory)) {
            New-Item -ItemType Directory -Path $backupSubDirectory | Out-Null
        }
        Copy-Item -Path $path.Value -Destination $backupFilePath -Force
        $resultObject.BackupPath = $backupFilePath
        Write-Host "Backed up '$($path.Value)' to '$backupFilePath'"

        # Validation Logic
        $extension = [System.IO.Path]::GetExtension($path.Value).ToLower()
        try {
            switch ($extension) {
                ".pem" {
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($path.Value)
                    $expirationDate = $cert.NotAfter
                    $resultObject.ExpiryDate = $expirationDate.ToString("o") # ISO 8601 format

                    Write-Host "Certificate '$($path.Key)' expires on: $expirationDate"

                    if ($expirationDate -lt (Get-Date)) {
                        $resultObject.Status = "Expired"
                        Write-Warning "Certificate '$($path.Key)' is EXPIRED!"
                    }
                    elseif ($expirationDate -le (Get-Date).AddDays(60)) {
                        $resultObject.Status = "Expiring within 60 days"
                        Write-Warning "Certificate '$($path.Key)' is expiring soon!"
                    }
                    else {
                        $resultObject.Status = "Valid"
                        Write-Host "Certificate '$($path.Key)' is valid." -ForegroundColor Green
                    }
                }
                ".crt" {
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($path.Value)
                    $expirationDate = $cert.NotAfter
                    $resultObject.ExpiryDate = $expirationDate.ToString("o") # ISO 8601 format

                    Write-Host "Certificate '$($path.Key)' expires on: $expirationDate"

                    if ($expirationDate -lt (Get-Date)) {
                        $resultObject.Status = "Expired"
                        Write-Warning "Certificate '$($path.Key)' is EXPIRED!"
                    }
                    elseif ($expirationDate -le (Get-Date).AddDays(60)) {
                        $resultObject.Status = "Expiring within 60 days"
                        Write-Warning "Certificate '$($path.Key)' is expiring soon!"
                    }
                    else {
                        $resultObject.Status = "Valid"
                        Write-Host "Certificate '$($path.Key)' is valid." -ForegroundColor Green
                    }
                }
                ".key" {
                    $resultObject.Status = "Skipped (Private Key)"
                    Write-Host "Skipping private key '$($path.Value)'."
                }
                default {
                    $resultObject.Status = "Skipped (Unsupported Type)"
                    Write-Host "File type '$extension' not validated: $($path.Value)"
                }
            }
        }
        catch {
            $resultObject.Status = "Error: $($_.Exception.Message)"
            Write-Warning "Failed to validate file '$($path.Value)'. Error: $_"
        }
    }
    else {
        $resultObject.Status = "Path not found"
        Write-Warning "Path for '$($path.Key)' does NOT exist: $($path.Value)"
    }

    # Add the completed object to the main report array
    $report += $resultObject
}

# --- 5. EXPORT AND FINISH ---
# Export the report to a JSON file
$report | ConvertTo-Json -Depth 2 | Set-Content -Path $reportFilePath
Write-Host "`nReport exported to $reportFilePath"

Write-Host "`nTask complete. Press Enter to close."
Read-Host