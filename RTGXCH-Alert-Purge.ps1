<#
.SYNOPSIS
    This script cleans up specified SQL log files by deleting them if they exist.

.DESCRIPTION
    The script iterates through a list of specified SQL log file paths and deletes each file if it exists. 
    If a file does not exist, it outputs a message indicating that the file does not exist.

.PARAMETERS
    None

.EXAMPLE
    .\RTGXCHAlerts_Cleanup.ps1
    This command runs the script and attempts to delete the specified SQL log files.

.NOTES
    Author: [Your Name]
    Date: [Date]
    The script uses a try-catch-finally block to handle any exceptions that may occur during the file deletion process.
#>
$SQLFiles = @("C:\Synanetics\SQL\RTGXCHAlerts.log", "C:\Synanetics\SQL\RTGXCHAlerts_Unsupported.log")

Try {
    Clear-Host
    ForEach ($SQLFile in $SQLFiles) {
        if (Test-Path -Path $SQLFile) {
            Try {
                Remove-Item $SQLFile -ErrorAction Stop
                Write-Output "$SQLFile has been deleted."
            } Catch {
                Write-Error "Failed to delete $SQLFile $_"
            }
        } else {
            Write-Output "$SQLFile does not exist."
        }
    }
} Catch {
    Write-Error "An error occurred: $_"
} Finally {
    Write-Output "Cleanup script execution completed."
}