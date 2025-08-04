# Optimized script to replicate WinDirStat functionality in PowerShell.
# This version is significantly faster by performing a single file system scan and using Group-Object for aggregation.

function Get-AllFolderSizes {
    param([string]$Path = "C:\")

    Write-Host "Starting a full file system scan of $Path... This may take a while." -ForegroundColor Cyan

    $startTime = Get-Date

    # Step 1: Get all files on the drive in a single, efficient pass.
    # The -Force parameter is added to include hidden and system files.
    $allFiles = Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue

    Write-Host "Scan complete. Aggregating file sizes..." -ForegroundColor Green
    
    $totalFiles = $allFiles.Count
    $processed = 0

    # Step 2: Aggregate the file sizes using a foreach loop and progress bar
    $folderSizes = @()
    
    # Group the files by their top-level folder
    # We use regex to find the root folder path from the FullName property
    # E.g., 'C:\Program Files\something.exe' will be grouped by 'C:\Program Files'
    $allFiles | Group-Object { $_.FullName -replace "^$([regex]::Escape($Path))([^\\]+\\).*$", '$1' } | ForEach-Object {
        $processed++
        
        # Display the progress bar
        Write-Progress -Activity "Aggregating folder sizes..." -Status "Processing: $($_.Name)" -PercentComplete (($processed / $totalFiles) * 100)
        
        # Create a custom object with the folder name and the calculated size
        $folderSizes += [PSCustomObject]@{
            Folder = "$Path$($_.Name)"
            SizeGB = [math]::Round( ($_.Group | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
        }
    }
    
    # Clean up the progress bar
    Write-Progress -Activity "Aggregating folder sizes..." -Completed
    
    # Step 3: Display the results
    $endTime = Get-Date
    $elapsedTime = New-TimeSpan -Start $startTime -End $endTime
    
    Write-Host "Aggregation complete." -ForegroundColor Green
    Write-Host "Total time elapsed: $($elapsedTime.TotalSeconds) seconds."
    Write-Host "--------------------"

    $folderSizes | Sort-Object -Property SizeGB -Descending | Format-Table -AutoSize
}

# Run the function
Get-AllFolderSizes