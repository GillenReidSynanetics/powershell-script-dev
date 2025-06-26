<#
.SYNOPSIS
    Script to provision a test environment for SSL management.

.DESCRIPTION
    This script prompts the user to confirm if they want to proceed with setting up a test environment. 
    If confirmed, it creates a timestamped directory and a predefined structure of files and folders 
    necessary for the test environment.

.PARAMETER None
    This script does not take any parameters.

.NOTES
    The script creates a directory named "TestEnvironment-<timestamp>" in the same directory as the script.
    Inside this directory, it creates the following structure:
    - .env (empty file)
    - docker-compose.yml (empty file)
    - jwt (empty folder)
    - ssl (empty folder)

.EXAMPLE
    To run the script, execute the following command in PowerShell:
    ./provision.ps1

    When prompted, enter "yes" to proceed with the test environment setup.
#>
$testenvConfirmation = Read-Host "Do you want to proceed with the test environment? (yes/no)"
$scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if ($testenvConfirmation -ne "yes") {
    Write-Host "Test environment process aborted."
    exit
} else {
    Write-Host "Running Test Environment Script..."
}

$testenvPath = Join-Path -Path $scriptPath -ChildPath "TestEnvironment-$timestamp"

try {
    New-Item -ItemType Directory -Path $testenvPath -Force | Out-Null
    Write-Host "Test environment folder created at: $testenvPath"
} catch {
    Write-Error "Failed to create test environment folder: $testenvPath. Error: $_"
    exit 1
}

$teststructure = @(
    ".env",
    "docker-compose.yml",
    "jwt",
    "ssl"
)

foreach ($item in $teststructure) {
    $itemPath = Join-Path -Path $testenvPath -ChildPath $item
    try {
        if ($item.EndsWith(".yml") -or $item.EndsWith(".env")) {
            # Create empty files
            New-Item -ItemType File -Path $itemPath -Force | Out-Null
            Write-Host "Created empty file: $itemPath"
        } else {
            # Create empty folders
            New-Item -ItemType Directory -Path $itemPath -Force | Out-Null
            Write-Host "Created empty folder: $itemPath"
        }
    } catch {
        Write-Error "Failed to create $item at: $itemPath. Error: $_"
        exit 1
    }
}

Write-Host "Test environment created successfully."
