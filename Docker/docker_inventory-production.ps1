
<#
.SYNOPSIS
    Collects Docker inventory information (containers, images, networks, volumes) and exports it to a CSV file.

.DESCRIPTION
    This script gathers detailed information about Docker containers, images, networks, and volumes on the local system.
    The collected data is exported to a CSV file for further analysis or reporting.
    The script checks for Docker installation before proceeding and handles errors gracefully.

.PARAMETER outputFile
    The path to the output CSV file where the Docker inventory data will be saved.
    Defaults to 'docker_data.csv' in the script's directory.

.FUNCTIONS
    Test-Docker
        Checks if Docker is installed and available in the system PATH.
    Get-DockerContainer
        Retrieves information about all Docker containers (running and stopped).
    Get-DockerImages
        Retrieves information about all Docker images.
    Get-DockerNetworks
        Retrieves information about all Docker networks.
    Get-DockerVolumes
        Retrieves information about all Docker volumes.

.OUTPUTS
    CSV file containing inventory data with columns for Type, ID, Name, Detail, Status, and Misc.

.EXAMPLE
    .\docker_inventory-dev.ps1
    Runs the script and saves the Docker inventory to 'docker_data.csv' in the script directory.

    .\docker_inventory-dev.ps1 -outputFile "C:\path\to\output.csv"
    Runs the script and saves the Docker inventory to the specified output file.

.NOTES
    - Requires Docker CLI to be installed and accessible in the system PATH.
    - Designed for use on systems with PowerShell and Docker installed.
    - Error messages are displayed if Docker is not installed or if data retrieval fails.

.AUTHOR
    [Your Name or Organization]
#>
param (
    [string]$outputFile = "$PSScriptRoot\docker_data.csv"
)

function Test-Docker {
    if (-not (Get-Command "docker" -ErrorAction SilentlyContinue)) {
        write-error "Docker not installed. Please install Docker and try again."
        exit 1
    }
}

function Get-DockerContainer {
 try {
    docker ps --all --format '{{json .}}' | ForEach-Object {
        $container = $_ | ConvertFrom-Json
        [PSCustomObject]@{
            Type   = "Container"
            ID     = $container.ID
            Name   = $container.Name 
            Image  = $container.Image
            Status = $container.Status
            Ports  = $container.Ports 
        }
    }
 }
 catch {
    Write-Error "Failed to retrieve Docker containers: $_"
 }


}
function Get-DockerImages {
    try {
        docker images --format '{{json .}}' | ForEach-Object {
            $image = $_ | ConvertFrom-Json
            [PSCustomObject]@{
                Type   = 'Image'
                ID     = $image.ID
                Name   = $image.Repository
                Detail = $image.Tag
                Status = $image.Size
                Misc   = '' # Placeholder for consistent columns
            }
        }
    } catch {
        Write-Error "Failed to retrieve Docker images: $_"
    }
}

function Get-DockerNetworks {
    try {
        docker network ls --format '{{json .}}' | ForEach-Object {
            $network = $_ | ConvertFrom-Json
            [PSCustomObject]@{
                Type   = 'Network'
                ID     = $network.ID
                Name   = $network.Name
                Detail = $network.Driver
                Status = $network.Scope
                Misc   = ''
            }
        }
    } catch {
        Write-Error "Failed to retrieve Docker networks: $_"
    }
}

function Get-DockerVolumes {
    try {
        docker volume ls --format '{{json .}}' | ForEach-Object {
            $volume = $_ | ConvertFrom-Json
            [PSCustomObject]@{
                Type   = 'Volume'
                ID     = '' # Volume ls doesn't provide a short ID
                Name   = $volume.Name
                Detail = $volume.Driver
                Status = ''
                Misc   = $volume.Mountpoint
            }
        }
    } catch {
        Write-Error "Failed to retrieve Docker volumes: $_"
    }
}

Test-Docker
$inventoryData = @()
Write-Host "Gathering Docker inventory..."

$inventoryData += Get-DockerContainers
$inventoryData += Get-DockerImages
$inventoryData += Get-DockerNetworks
$inventoryData += Get-DockerVolumes

if ($inventoryData.Count -gt 0) {
    try {
        $inventoryData | Export-Csv -Path $outputFile -NoTypeInformation -Force
        Write-Host "Inventory complete. Data saved to $outputFile" -ForegroundColor Green
    } catch {
        Write-Error "Failed to write to CSV file at ${outputFile}: $_"
    }
} else {
    Write-Warning "No Docker inventory data was collected."
}

Write-Progress -Activity "Docker Inventory" -Completed -Status "Finished"
exit 0