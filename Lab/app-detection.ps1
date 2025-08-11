<#
.SYNOPSIS
    Script to detect the presence of a specified application on a Windows machine.

.DESCRIPTION
    This script checks for the presence of an application by name using the Win32_Product class.
    It sets the execution policy to RemoteSigned for the current process to allow script execution.
    If the application is found, it returns an exit code of 0, indicating to Intune that the application is installed.
    If the application is not found, it returns an exit code of 1, indicating to Intune that the application is not installed.

.PARAMETER AppName
    The name of the application to detect. Replace "(APP-NAME-GOES-HERE)" with the actual application name.

.EXAMPLE
    .\app-detection.ps1
    This example runs the script and checks for the specified application.
#>

# Set execution policy
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope Process -Force

# App name to detect
$AppName = "(APP-NAME-GOES-HERE)"

# Check for installed applications matching the name
$appExists = Get-CimInstance -ClassName Win32_Product | Where-Object { $_.Name -like "*$AppName*" }

if ($appExists) {
    # App found, return exit code 0 for Intune to recognize as "installed"
    Write-Host "Application '$AppName' found."
    exit 0 
} else {
    # App not found, return exit code 1 for Intune to recognize as "not installed"
    Write-Host "Application '$AppName' not found."
    exit 1
}
