$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $scriptDir "$ContainerName-logs-$timestamp.txt"
$containerName = Read-Host "Please enter the container name or ID"


# Prompt user for number of lines to tail
$TailLinesInput = Read-Host "Enter number of log lines to show (default is 20)"
if (-not [int]::TryParse($TailLinesInput, [ref]$null)) {
    $TailLines = 20
} else {
    $TailLines = [int]$TailLinesInput
}



# Error Handling Block
#================

# Check if Docker is installed and available in PATH
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH."
    exit 1
}
# Validate the container name or ID
$container = docker ps --format "{{.Names}}" | Where-Object { $_ -eq $ContainerName }
if (-not $container) {
    Write-Error "Container '$ContainerName' is not running."
    exit 1
}

#===============


# Saves log sample for examination
Write-Host "Saving last $TailLines lines of logs from '$ContainerName' to '$logFile'..."
docker logs --tail $TailLines $ContainerName | Out-File -Encoding UTF8 $logFile