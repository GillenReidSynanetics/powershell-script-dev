<#
.SYNOPSIS
    Cleans up backup folders created by the script.

.DESCRIPTION
    This script searches for backup folders in the same directory as the script and removes them. 
    It logs the removal of each folder or any errors encountered during the process.

.PARAMETERS
    None.

.EXAMPLE
    .\Clean-Up.ps1
    This command runs the cleanup script, removing any backup folders in the script's directory.

.NOTES
    The script uses the pattern "BackupFolder*" to identify backup folders.
    It handles errors gracefully, logging warnings for individual folder removal failures and errors for retrieval failures.
#>
Write-Host "Cleaning up files created by this script..."
$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$backupFolderPattern = Join-Path -Path $scriptPath -ChildPath "BackupFolder*"  # Define the backup folder path pattern
try {
    $backupFolders = Get-ChildItem -Path $backupFolderPattern -Directory -ErrorAction Stop

    if ($backupFolders.Count -gt 0) {
        foreach ($folder in $backupFolders) {
            try {
                Remove-Item -Path $folder.FullName -Recurse -Force -ErrorAction Stop
                Write-Host "Removed backup folder: $($folder.FullName)"
            } catch {
                Write-Warning "Failed to remove backup folder: $($folder.FullName). Error: $_"
            }
        }
    } else {
        Write-Host "No backup folders to remove."
    }
} catch {
    Write-Error "Failed to retrieve backup folders. Error: $_"
}
exit
