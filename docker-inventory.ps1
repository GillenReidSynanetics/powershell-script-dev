<#
.SYNOPSIS
    Collects and exports Docker inventory data to a CSV file.

.DESCRIPTION
    This script collects information about Docker containers, images, networks, and volumes,
    and exports the data to a specified CSV file. If the file does not exist, it creates one
    with the appropriate headers.

.PARAMETER outputFile
    The path to the CSV file where the Docker inventory data will be saved. Defaults to "docker_data.csv"
    in the script's directory.

.FUNCTIONS
    Test-Docker
        Checks if Docker is installed on the system. If not, it writes an error and exits the script.

    get-docker-containers
        Retrieves information about Docker containers and appends it to the CSV file.

    get-docker-images
        Retrieves information about Docker images and appends it to the CSV file.

    get-docker-networks
        Retrieves information about Docker networks and appends it to the CSV file.

    get-docker-volumes
        Retrieves information about Docker volumes and appends it to the CSV file.

.EXAMPLE
    .\docker-inventory.ps1
    Runs the script and saves the Docker inventory data to "docker_data.csv" in the script's directory.

.EXAMPLE
    .\docker-inventory.ps1 -outputFile "C:\path\to\output\docker_inventory.csv"
    Runs the script and saves the Docker inventory data to the specified path.
#>
param (
    [string]$outputFile = "$PSScriptRoot\docker_data.csv"
)

# Ensure the script runs with elevated privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator."
    exit 1
}

if (-not (Test-Path -Path $outputFile)) {
    Write-Output "Creating log file at $outputFile"
    New-Item -Path $outputFile -ItemType File -Force
} else {
    Write-Output "Log file already exists at $outputFile"
}

function Test-Docker {
    if (-not(Get-Command "docker" -ErrorAction SilentlyContinue)) {
        Write-Error "Docker not installed"
        exit 1
    }
}

function get-docker-containers {
    try {
        if (-not (Test-Path $outputFile)) {
            "Type,ID,Name,Image,Status,Ports" | Out-File -FilePath $outputFile -Append
        }
        docker ps --format "ID={{.ID}},Name={{.Names}},Image={{.Image}},Status={{.Status}},Ports={{.Ports}}" | ForEach-Object { "Container,$_" } | ConvertFrom-Csv | Export-Csv -Path $outputFile -Append -NoTypeInformation -Force
    } catch {
        Write-Error "Failed to retrieve Docker containers: $_"
    }
}

function get-docker-images {
    try {
        if (-not (Test-Path $outputFile)) {
            "Type,ID,Repository,Tag,Size" | Out-File -FilePath $outputFile -Append
        }
        docker images --format "ID={{.ID}},Repository={{.Repository}},Tag={{.Tag}},Size={{.Size}}" | ForEach-Object { "Image,$_" } | ConvertFrom-Csv | Export-Csv -Path $outputFile -Append -NoTypeInformation -Force
    } catch {
        Write-Error "Failed to retrieve Docker images: $_"
    }
}

function get-docker-networks {
    try {
        if (-not (Test-Path $outputFile)) {
            "Type,ID,Name,Driver" | Out-File -FilePath $outputFile -Append
        }
        docker network ls --format "ID={{.ID}},Name={{.Name}},Driver={{.Driver}}" | ForEach-Object { "Network,$_" } | ConvertFrom-Csv | Export-Csv -Path $outputFile -Append -NoTypeInformation -Force
    } catch {
        Write-Error "Failed to retrieve Docker networks: $_"
    }
}

function get-docker-volumes {
    try {
        if (-not (Test-Path $outputFile)) {
            "Type,Name,Driver,Scope" | Out-File -FilePath $outputFile -Append
        }
        docker volume ls --format "Name={{.Name}},Driver={{.Driver}},Scope={{.Scope}}" | ForEach-Object { "Volume,$_" } | ConvertFrom-Csv | Export-Csv -Path $outputFile -Append -NoTypeInformation -Force
    } catch {
        Write-Error "Failed to retrieve Docker volumes: $_"
    }
}

Test-Docker
get-docker-containers
get-docker-images
get-docker-networks
get-docker-volumes

Write-Host "Inventory saved to $outputFile"