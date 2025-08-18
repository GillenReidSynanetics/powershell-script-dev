# The main 'try' block wraps the entire operation.
try {
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
    
    $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $backupFolder = Join-Path -Path $scriptPath -ChildPath "BackupFolder $timestamp"
    
    # Create the backup folder. If this fails, the whole script should stop.
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
 
    # Define the items to back up
    $itemsToBackup = @(
        @{ Name = 'docker-compose-manda.yml'; IsDirectory = $false },
        @{ Name = 'docker-compose.yml'; IsDirectory = $false },
        @{ Name = 'certs'; IsDirectory = $true },
        @{ Name = 'ssl'; IsDirectory = $true } 
    )

    # Loop through each item to back it up
    foreach ($item in $itemsToBackup) {
        # FIX: Each item gets its OWN try/catch block inside the loop.
        # This allows the loop to continue even if one item fails.
        try {
            $sourcePath = Join-Path -Path $scriptPath -ChildPath $item.Name
            
            if (Test-Path -Path $sourcePath) {
                $copyParams = @{
                    Path        = $sourcePath
                    Destination = $backupFolder
                    Force       = $true
                    ErrorAction = 'Stop'
                }

                if ($item.IsDirectory) {
                    $copyParams.Add('Recurse', $true)
                }
                
                Copy-Item @copyParams
                Write-Host "✅ Copied $($item.Name)"
            } 
            else {
                Write-Warning "⚠️ '$($item.Name)' does not exist and was skipped."
            }
        }
        catch {
            # This catch block is specific to the item that failed.
            Write-Error "❌ An error occurred while copying '$($item.Name)': $_"
        }
    }

    # REFINEMENT: The success message belongs at the end of the 'try' block.
    Write-Host "`nBackup process completed. See output for details." -ForegroundColor Green
}
catch {
    # FIX: The main 'catch' block now correctly follows the main 'try' block.
    # This will only catch critical errors, like failing to create the backup folder.
    Write-Error "A critical error occurred: $_"
}
finally {
    # REFINEMENT: The 'finally' block is for cleanup that ALWAYS runs.
    # Restoring the execution policy is a perfect use case for 'finally'.
    Write-Verbose "Restoring original execution policy."
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Undefined -Force
}