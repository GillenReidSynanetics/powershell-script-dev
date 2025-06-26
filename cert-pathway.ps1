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
$scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
$envFilePath = Join-Path -Path $scriptDirectory -ChildPath ".env"
$backupDirectory = Join-Path -Path $scriptDirectory -ChildPath "backups"
$dateSuffix = Get-Date -Format "yyyyMMdd-HHmmss"
$reportFilePath = Join-Path -path $scriptDirectory -ChildPath "report.json"


$report = @()

# Reports back confirming it can't find .env
if (-not (Test-Path -Path $envFilePath)) {
    Write-Error "File not found $envFilePath"
    exit 1
}

$envVariables = Get-Content $envFilePath | Where-Object { $_ -match "=" }

$potentialPaths = @()

# Checks pathways for all files mentioned in pathways on .env
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

# Reports back it hasn't found any pathways (most likely have the script in the wrong location)
if ($potentialPaths.Count -eq 0) {
    Write-Host "No file paths found in the .env file."
    exit 0
}

# Reporting back on results.
foreach ($path in $potentialPaths) {
    $exists = Test-Path -Path $path.Value
    if ($exists) {
        Write-Host "Path for '$($path.Key)' exists: $($path.Value)"

        # Replication before validation
        $backupSubDirectory = Join-Path -Path $backupDirectory -ChildPath (Split-Path -Parent $path.Value)
        $backupFilePath = Join-Path -Path $backupSubDirectory -ChildPath ("$(Split-Path $path.Value -Leaf)-$dateSuffix")

        # Create backup directory
        if (-not (Test-Path -Path $backupSubDirectory)) {
            New-Item -ItemType Directory -Path $backupSubDirectory | Out-Null
            Write-Host "Created backup SubDirectory $backupSubdirectory"
        }
        
        # Copy files to backup directory
        Copy-Item -Path $path.Value -Destination $backupFilePath -Force
        Write-Host "Replicated '$($path.Value)' to '$backupFilePath'"


        # File extension validation (dev)
        $extension = [System.IO.Path]::GetExtension($path.Value).ToLower()
        try {
            switch ($extension) {
                ".pem" {
                    # Validate .pem certificate expiry dates
                    $certContent = Get-Content -Path $path.Value -Raw
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $cert.Import([System.Text.Encoding]::UTF8.GetBytes($certContent))

                    $expirationDate = $cert.NotAfter
                    $now = Get-Date

                    Write-Host "Certificate '$($path.Key)' expires on: $expirationDate"

                    if ($expirationDate -lt $now) {
                        Write-Warning "Certificate '$($path.Key)' is expired!"
                    } elseif ($expirationDate -le $now.AddDays(60)) {
                        Write-Warning "Certificate '$($path.Key)' is expiring in 60 days!"
                    } else {
                        Write-Host "Certificate '$($path.Key)' validated and is valid." -ForegroundColor Green
                    }
                }
                ".crt" {
                    # Validate .crt certificate expiry dates
                    $certContent = Get-Content -Path $path.Value -Raw
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $cert.Import([System.Text.Encoding]::UTF8.GetBytes($certContent))

                    $expirationDate = $cert.NotAfter
                    $now = Get-Date

                    Write-Host "Certificate '$($path.Key)' expires on: $expirationDate"

                    if ($expirationDate -lt $now) {
                        Write-Warning "Certificate '$($path.Key)' is expired!"
                    } elseif ($expirationDate -le $now.AddDays(60)) {
                        Write-Warning "Certificate '$($path.Key)' is expiring in 60 days!"
                    } else {
                        Write-Host "Certificate '$($path.Key)' validated and is valid." -ForegroundColor Green
                    }
                }
                ".key" {
                    Write-Host "Skipping private key '$($path.Value)' as it does not have an expiry date."
                }
                default {
                    Write-Host "File type not explicitly validated: $($path.Value)"
                }
            } # End switch
        } catch {
            Write-Warning "Failed to validate file '$($path.Value)'. Error: $_"
        }
    } else {
        Write-Warning "Path for '$($path.Key)' does NOT exist: $($path.Value)"
    }
} # End foreach

$report | ConvertTo-Json -Depth 2 | Set-Content -Path $reportFilePath
Write-Host "Report Exported to $reportFilePath"

Write-Host "Task complete - Please press enter to close"
Read-Host