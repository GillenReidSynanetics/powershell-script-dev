<#
.SYNOPSIS
    Script to automatically restart a specified service and log the actions.

.DESCRIPTION
    This script stops and starts a specified service, logging each action to a log file. 
    It is designed to be used with scheduled tasks but can be adapted for any service.

.PARAMETER logFilePath
    The path to the log file where messages will be recorded.

.PARAMETER message
    The message to be logged.

.FUNCTIONS
    Log-Message
        Logs a message with a timestamp to the specified log file.

.NOTES
    File Name  : reboot-script.ps1
    Author     : GillenReidSynanetics
    Version    : 1.0
    Requires   : PowerShell 5.0 or later

.EXAMPLE
    .\reboot-script.ps1
    This will execute the script, stopping and starting the specified service and logging the actions.

#>
# Script was originally designed for automatically restarting a service via scheduled tasks - can be adapted for any service


# Define the log file path
$logFilePath = "C:\[foldercreated]\*relevantnamingscheme*.txt"

# Create the log file if it doesn't exist
if (-not (Test-Path -Path $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath -Force
}

# Function to log messages
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logMessage
}

# Log the start of the script
Write-Log "Script started."

# Stop the service
try {
    Stop-Service -Name #servicenamehere -Force -ErrorAction Stop
    Write-Log "Stopped."
} catch {
    Write-Log "Failed: $_"
}

# Start the Service
try {
    Start-Service -Name #servicenamehere -ErrorAction Stop
    Write-Log "Service Started."
} catch {
    Write-Log "Failed: $_"
}

# Log the end of the script
Write-Log "Script completed."