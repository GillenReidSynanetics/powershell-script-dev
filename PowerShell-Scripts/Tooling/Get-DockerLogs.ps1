<#
.SYNOPSIS
    Retrieves and analyzes recent logs from a specified or selected Docker container.

.DESCRIPTION
    The Get-DockerLogSample function fetches logs from a Docker container for the past specified number of hours (default is 2).
    It allows filtering log output by a keyword, highlights error and warning lines, and optionally saves matched lines to a file.
    If no container name is provided, the function prompts the user to select from running containers.

.PARAMETER ContainerName
    The name or ID of the Docker container to retrieve logs from. If not specified, the user will be prompted to select a running container.

.PARAMETER Hours
    The number of hours of logs to retrieve from the container. Defaults to 2.

.PARAMETER Filter
    An optional string to filter the log output. Only lines containing this keyword will be included in the results.

.PARAMETER LogToFile
    If specified, saves all error and warning lines to a timestamped log file in the script directory.

.PARAMETER Tail
    The number of most recent log lines to retrieve. Defaults to 100.

.EXAMPLE
    Get-DockerLogSample -ContainerName "my-app" -Hours 4 -Filter "Exception" -LogToFile

    Retrieves the last 4 hours of logs from the "my-app" container, filters for lines containing "Exception",
    displays a summary, and saves error and warning lines to a file.

.EXAMPLE
    Get-DockerLogSample

    Prompts the user to select a running container, retrieves the last 2 hours of logs, and displays a summary.

.NOTES
    - Requires Docker CLI to be installed and available in the system PATH.
    - The function must be run with sufficient permissions to access Docker.
    - The log file is saved in the same directory as the script.

#>
# Parameter validation and function definition

function Get-DockerLogSample {
    [CmdletBinding()]
    param (
        [string]$ContainerName,
        [int]$Hours = 2,
        [string]$Filter,
        [switch]$LogToFile,
        [int]$Tail = 100
    )

    $selectedContainerName = $ContainerName

    # if loop to look at exising containers
    if (-not $ContainerName) {
        try {
            $runningContainers = docker ps  --format "{{.ID}}`t{{.Names}}`t{{.Image}}" 
        }
        # error handling for docker ps command
        catch {
            Write-Error "Failed to retrieve running containers. Ensure Docker is running."
            return
        }
        if (-not $runningContainers) {
            Write-Error "No running containers found."
            return
        }
        # Display the list of running containers
        Write-Host "Please select a running container from the list below:"
        for ($i = 0; $i -lt $runningContainers.Count; $i++) {
            Write-Host "[$($i + 1)] $($runningContainers[$i])"
        }
       # Prompt the user to select a container
        $choice = Read-Host "Enter the number of the container"
        if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $runningContainers.Count) {
            
            $selection = $runningContainers[[int]$choice - 1].Split("`t")
            $ContainerName = $selection[0]
            $selectedContainerName = $selection[1] # Get the Name
        }
        # error handling for invalid input
        else {
            Write-Error "Invalid selection."
            return
        }
    }

    # generate the log file name based on the selected container name
    Write-Host "Fetching logs for container: $ContainerName for the last $Hours hours..."
    try {
        $logs = docker logs --since "$($Hours)h" --tail $Tail $ContainerName
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "Failed to retrieve logs for container $ContainerName. Please check if the container is running and Docker is functioning correctly."
            return
        }

    }
    catch {
        Write-Error "Failed to retrieve logs for container $ContainerName. Ensure the container is running and Docker is functioning correctly."
        return
    }

    # Filtering section to pick up any errors. Can be extended to include more filters.
    if ($Filter) {
        $logs = $logs | Select-String -Pattern $Filter -CaseSensitive
    }
    
    # Find and store the matching lines first. This is also more efficient.
    $errorLines = $logs | Select-String -Pattern 'ERROR' -CaseSensitive
    $warningLines = $logs | Select-String -Pattern 'WARN' -CaseSensitive

    # Display the summary and return the log data.
    Write-Host "`n--- Analysis Summary ---"
    Write-Host "Total lines found: $($logs.Count)" -ForegroundColor Green
    Write-Host "Error lines found: $($errorLines.Count)" -ForegroundColor ($errorLines.Count -gt 0 ? 'Red' : 'Green')
    Write-Host "Warning lines found: $($warningLines.Count)" -ForegroundColor ($warningLines.Count -gt 0 ? 'Yellow' : 'Green')
    

    # if loop to generate a log file if the LogToFile switch is specified
    if ($LogToFile) {
        $matchedLines = $errorLines, $warningLines
        if ($matchedLines.Count -gt 0) {
            $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            $logFileName = "$($selectedContainerName)_errors_$timestamp.txt"
            $logPath = Join-Path -Path $PSScriptRoot -ChildPath $logFileName
        
            Write-Host "Saving matched lines to: $logPath" -ForegroundColor Cyan
            $matchedLines | ForEach-Object { $_.Line } | Out-File -FilePath $logPath -Encoding utf8
        }
    }
    Write-Host "----------------------`n"
    # Return the actual log lines to the pipeline so they can be used by other commands.
    return $logs
}
