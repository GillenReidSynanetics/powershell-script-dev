try {
    # Set execution policy for the current process
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

    # --- 1. SETUP ---
    # Get the script's path and create a timestamped backup folder
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolder = Join-Path -Path $scriptPath -ChildPath "BackupFolder $timestamp"
    New-Item -ItemType Directory -Path $backupFolder -Force
    
    # --- 2. DEFINE ITEMS TO BACK UP ---
    $filesToBackup = @(
        '.env',
        'docker-compose.yml'
    )
    $foldersToBackup = @(
        'jwt',
        'ssl'
    )

    # --- 3. PROCESS FILES ---
    foreach ($file in $filesToBackup) {
        $sourcePath = Join-Path -Path $scriptPath -ChildPath $file
        if (Test-Path -Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $backupFolder -ErrorAction Stop
        } else {
            Write-Warning "'$file' does not exist."
        }
    }

    # --- 4. PROCESS FOLDERS ---
    foreach ($folder in $foldersToBackup) {
        $sourcePath = Join-Path -Path $scriptPath -ChildPath $folder
        if (Test-Path -Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $backupFolder -Recurse -ErrorAction Stop
        } else {
            Write-Warning "'$folder' does not exist."
        }
    }

    Write-Host "Backup complete. Files saved in '$backupFolder'"
} catch {
    Write-Error "An error occurred during backup: $_"
}
finally {
    # Reset execution policy to default
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined -Force
}