<#
.SYNOPSIS
Fetches and filters logs from a specified Docker container for common error keywords.

.DESCRIPTION
This script retrieves logs from a Docker container specified by the user and filters the output for lines containing common error-related keywords such as "error", "failed", "exception", "critical", "unable", "panic", and "traceback". It provides real-time log monitoring and highlights potential issues in the container logs.

.PARAMETER ContainerName
The name of the Docker container from which to fetch logs. This parameter is mandatory.

.EXAMPLE
.\logging-script.ps1 -ContainerName my-container

Fetches and displays logs from 'my-container', filtering for error keywords.

.NOTES
Requires Docker to be installed and accessible from the command line.
#>
param(
    [Parameter(Mandatory=$true)]
    [string]$ContainerName)
# Define error keywords to search for in the logs
$errorKeywords = @("error", "failed", "exception", "critical", "unable", "panic", "traceback") # Standard Errors to catch?
$pattern = $errorKeywords -join "|"

Write-Host "Fetching logs for container: $ContainerName"
Write-Host "Looking for error key words $pattern"

try {
    docker logs -f $ContainerName | Select-String -Pattern $pattern -SimpleMatch
}
catch {
    Write-Error "An error occurred while fetching logs: $_"
    exit 1
}

