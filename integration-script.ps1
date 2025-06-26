<#
.SYNOPSIS
  Backs up static and dynamically discovered SSL-related files, validates certificates, and generates a backup report.

.DESCRIPTION
  This script performs the following operations:
  - Sets the execution policy to bypass for the current process.
  - Determines the script's directory and creates a timestamped backup folder.
  - Backs up static files: 'docker-compose.yml', '.env', 'jwt', and 'ssl' if they exist - can be edited to add and remove.
  - Parses the .env file to discover certificate and key file paths.
  - Backs up discovered certificate and key files, preserving relative paths.
  - Validates certificate files (.crt, .pem) for expiry and reports their status.
  - Generates a JSON report summarizing the backup and validation results.
  - Handles errors gracefully and provides user feedback throughout the process.

.PARAMETER None
  All configuration is handled internally; no external parameters are required.

.OUTPUTS
  - Backup folder containing copies of static and discovered files.
  - JSON report file ('report.json') summarizing backup and validation status.

.NOTES
  - Requires appropriate permissions to read source files and write to the backup directory.
  - Designed for use in environments where SSL/TLS certificates and keys are managed via environment variables.

.AUTHOR - Gillen Reid
  synanetics.com

.EXAMPLE
  .\replication_script copy.ps1
  Runs the script, performs backups, validates certificates, and generates a report.
#>
try {
    # =====================
    # Variables
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force #Setting execution policy to bypass for the current process
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent # Get the directory of the script
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss" # Create a timestamp for the backup folder - allows for multiple backups without overwriting and for easy identification
    $backupFolder = Join-Path -Path $scriptPath -ChildPath "BackupFolder $timestamp" # Create a timestamped backup folder
    $envFilePath = Join-Path -Path $scriptPath -ChildPath ".env" # Path to the .env file
    $reportFilePath = Join-Path -path $scriptPath -ChildPath "report.json" # Path to the report file
    $report = @() # Initialize an array to hold report data

    # Create master backup folder
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null

    # =====================
    # Static File Backups
    $itemsToBackup = @('docker-compose.yml', '.env', 'jwt', 'ssl') # Can be amended to include more items

    foreach ($item in $itemsToBackup) {
        $source = Join-Path -Path $scriptPath -ChildPath $item
        if (Test-Path -Path $source) {
            $destination = Join-Path -Path $backupFolder -ChildPath $item
            $isDirectory = (Get-Item $source).PSIsContainer
            Copy-Item -Path $source -Destination $destination -Recurse:$isDirectory -Force
            Write-Host "✅ Backed up '$item'"
        }
        else {
            Write-Warning "⚠️ '$item' does not exist and was skipped."
        }
    } # for each loop to backup static files

    # =====================
    # Dynamic .env Discovery + Backup
    # Check if .env file exists - I have found that enviroments are sometime not given a .env file, potentially different naming conventions
    # Block of code will read .env and validate any certs/keys found
    if (-not (Test-Path -Path $envFilePath)) {
        Write-Error "❌ File not found: $envFilePath"
        exit 1
    }

    $envVariables = Get-Content $envFilePath | Where-Object { $_ -match "=" }
    $potentialPaths = @()

    foreach ($line in $envVariables) {
        if ($line -match '^[A-Z_]+=(.+\.(crt|key|pem))$') {
            $key, $value = $line -split "=", 2
            $value = $value.Trim('"', "'") -replace "file://", ""
            $potentialPaths += [PSCustomObject]@{
                Key   = $key
                Value = $value
            }
        }
    }

    if ($potentialPaths.Count -eq 0) {
        Write-Host "⚠️ No cert file paths found in the .env file."
    }

    foreach ($path in $potentialPaths) {
        $exists = Test-Path -Path $path.Value
        if ($exists) {
            Write-Host "📁 Found: $($path.Key) => $($path.Value)"
            
            # Backup dynamic cert/key
            $relative = $path.Value.Replace($scriptPath, "").TrimStart('\')
            $targetBackupPath = Join-Path -Path $backupFolder -ChildPath ("certs\$relative-$timestamp")

            $targetBackupDir = Split-Path -Parent $targetBackupPath
            if (-not (Test-Path -Path $targetBackupDir)) {
                New-Item -ItemType Directory -Path $targetBackupDir -Force | Out-Null
            }

            Copy-Item -Path $path.Value -Destination $targetBackupPath -Force
            Write-Host "📄 Backed up cert: $targetBackupPath"

            # Validation
            $extension = [System.IO.Path]::GetExtension($path.Value).ToLower()
            $expiry = $null
            $status = "Unknown"

            try {
                if ($extension -in @(".crt", ".pem")) {
                    $certContent = Get-Content -Path $path.Value -Raw
                    $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
                    $cert.Import([System.Text.Encoding]::UTF8.GetBytes($certContent))
                    $expiry = $cert.NotAfter

                    if ($expiry -lt (Get-Date)) {
                        Write-Warning "❗ Certificate expired: $expiry"
                        $status = "Expired"
                    }
                    elseif ($expiry -le (Get-Date).AddDays(60)) {
                        Write-Warning "⚠️ Certificate expiring soon: $expiry"
                        $status = "Expiring Soon"
                    }
                    else {
                        Write-Host "✅ Certificate valid: $expiry" -ForegroundColor Green
                        $status = "Valid"
                    }
                }
                elseif ($extension -eq ".key") {
                    Write-Host "🔑 Private key found (no expiry): $($path.Value)"
                    $status = "Key - No Expiry"
                }
            }
            catch {
                Write-Warning "❌ Failed to validate file '$($path.Value)': $_"
                $status = "Validation Failed"
            }

            $report += [PSCustomObject]@{
                Key    = $path.Key
                Path   = $path.Value
                Exists = $exists
                Expiry = $expiry
                Status = $status
            }
        }
        else {
            Write-Warning "❌ Path for '$($path.Key)' does NOT exist: $($path.Value)"
            $report += [PSCustomObject]@{
                Key    = $path.Key
                Path   = $path.Value
                Exists = $false
                Status = "Missing"
            }
        }
    }

    # Save report
    $report | ConvertTo-Json -Depth 2 | Set-Content -Path $reportFilePath
    Write-Host "`n📋 Report written to: $reportFilePath"
    
}

catch {
    Write-Error "❌ Unhandled error: $_"
}

# Discovered it was possible to zip the backup folder and remove it after zipping
# This is to ensure the backup folder is compressed and cleaned up after the script runs
finally {
    if (![string]::IsNullOrWhiteSpace($backupFolder) -and (Test-Path $backupFolder)) {
        Write-Host "`n🎯 Backup complete. Folder: $backupFolder"
        $zipPath = "$backupFolder.zip"

        try {
            Compress-Archive -Path $backupFolder -DestinationPath $zipPath -Force
            Write-Host "📦 Backup folder compressed to: $zipPath"
            Remove-Item -Path $backupFolder -Recurse -Force
            Write-Host "🧹 Original backup folder removed."
        }
        catch {
            Write-Warning "❌ Failed to zip or clean up backup folder: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Skipping compression and cleanup: backup folder path was not valid or was never created."
    }

    Read-Host "Press Enter to exit"
}
