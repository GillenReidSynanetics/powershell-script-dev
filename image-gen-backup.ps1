<#
.SYNOPSIS
  Backs up specified files in the script directory, names the backup with a Change Request ticket number and timestamp, compresses the backup, and cleans up the original folder.

.DESCRIPTION
  This script prompts the user for a Change Request ticket number, creates a timestamped backup folder, and copies specified files (e.g., 'docker-compose.yml', '.env') from the script's directory into the backup folder. After copying, it compresses the backup folder into a ZIP archive and removes the original backup folder. The script provides status messages throughout the process.

.PARAMETER changeID
  The Change Request ticket number entered by the user, used to name the backup folder.

.NOTES
  - The list of files to back up can be modified in the $itemsToBackup array.
  - The script sets the execution policy to Bypass for the current process to ensure compatibility.
  - Requires PowerShell 5.0 or later for Compress-Archive cmdlet.

.EXAMPLE
  PS> .\image-gen-backup.ps1
  Enter the Change Request ticket number: 12345
  ✅ Backed up 'docker-compose.yml'
  ✅ Backed up '.env'
  🎯 Backup complete. Folder: C:\path\to\script\CR-12345 20240610_153000
  📦 Backup folder compressed to: C:\path\to\script\CR-12345 20240610_153000.zip
  🧹 Original backup folder removed.

#>

do {
    $changeID = Read-Host "Enter the Change Request ticket number (3 Digits e.g. 345)"
} while ($changeID -notmatch '^\d{3}$')

try {
  
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
  $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
  $backupFolder = Join-Path -Path $scriptPath -ChildPath "CR-$changeID $timestamp"
  New-Item -ItemType Directory -Path $backupFolder -Force
  $itemsToBackup = @('docker-compose.yml', '.env') # Can be amended to include more items

    foreach ($item in $itemsToBackup) {
        $source = Join-Path -Path $scriptPath -ChildPath $item
        if (Test-Path -Path $source) {
            $destination = Join-Path -Path $backupFolder -ChildPath $item
            Copy-Item -Path $source -Destination $destination -Recurse -Force
            Write-Host "Backed up '$item'"
            if (-not (Test-Path $destination -PathType Container)){
              $hash = Get-FileHash -Path $destination -Algorithm SHA256
              Write-Host "File hash for '$item': $($hash.Hash)"
            }
        }
        else {
            Write-Warning "'$item' does not exist and was skipped."
        }
    } # for each loop to backup static files
  }
finally {
    if (![string]::IsNullOrWhiteSpace($backupFolder) -and (Test-Path $backupFolder)) {
        Write-Host "`Backup complete. Folder: $backupFolder"
        $zipPath = "$backupFolder.zip"
        try {
            Compress-Archive -Path $backupFolder -DestinationPath $zipPath -Force
            Write-Host "Backup folder compressed to: $zipPath"
            Remove-Item -Path $backupFolder -Recurse -Force
            Write-Host "Original backup folder removed."
        }
        catch {
            Write-Warning "Failed to zip or clean up backup folder: $($_.Exception.Message)"
        }
    } else {
        Write-Warning "Skipping compression and cleanup: backup folder path was not valid or was never created."
    }
    Read-Host "Press Enter to exit"
}
# Tested Locally and Verified as working