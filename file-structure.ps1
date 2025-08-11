<#
.SYNOPSIS
    Generates an inventory report of files and directories within a specified target directory.

.DESCRIPTION
    This script scans a target directory and its subdirectories to collect information about files and folders.
    It generates an inventory report in CSV format, including details such as name, full path, type (file or folder),
    size (for files), and last modified date.

.PARAMETER TargetDirectory
    The directory to scan. By default, it is set to the directory where the script is located.

.OUTPUTS
    A CSV file containing the inventory report.

.NOTES
    The output CSV file is saved in the target directory with the name 'inventory.csv'.

.EXAMPLE
    .\file-structure.ps1
    This example runs the script and generates an inventory report for the directory where the script is located.

#>
# Define the directory to scan (change this to your target directory)
$TargetDirectory = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

# Output file path
$OutputFile = "$targetDirectory\folder-structure-inventory.csv"

# Collect inventory data
$Inventory = Get-ChildItem -Path $TargetDirectory -Recurse | ForEach-Object {
    [PSCustomObject]@{
        Name           = $_.Name
        FullPath       = $_.FullName
        Type           = if ($_.PSIsContainer) { "Folder" } else { "File" }
        Size           = if (-not $_.PSIsContainer) { $_.Length } else { $null }
        LastModified   = $_.LastWriteTime
    }
}

# Export to CSV
$Inventory | Export-Csv -Path $OutputFile -NoTypeInformation

Write-Host "Inventory report generated: $OutputFile"
