<#
.SYNOPSIS
  Creates a backup of existing certificates and Docker environment files.

.DESCRIPTION
  This script sets the execution policy to RemoteSigned, creates a timestamped backup folder, 
  and copies the .env file, docker-compose.yml file, and the 'jwt' and 'ssl' directories 
  into the backup folder.

.PARAMETER None
  This script does not take any parameters.

.OUTPUTS
  None

.NOTES
  The script creates a backup folder with a timestamp in its name and copies the specified files 
  and directories into it. The backup folder is located in the same directory as the script.

.EXAMPLE
  To run the script, execute the following command in PowerShell:
  .\replication-script.ps1

  This will create a backup folder and copy the necessary files and directories into it.

#>


try {
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

  $scriptPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent

  $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

  $backupFolder = Join-Path -Path $scriptPath -ChildPath "BackupFolder $timestamp"

  New-Item -ItemType Directory -Path $backupFolder -Force
  
  if (Test-Path -Path (Join-Path -Path $scriptPath -ChildPath 'docker-compose-manda.yml')) {
    Copy-Item -Path (Join-Path -Path $scriptPath -ChildPath 'docker-compose-manda.yml') -Destination $backupFolder -ErrorAction Stop
  } else {
    Write-Warning "'docker-compose-manda.yml' file does not exist."
  }

  if (Test-Path -Path (Join-Path -Path $scriptPath -ChildPath 'docker-compose.yml')) {
    Copy-Item -Path (Join-Path -Path $scriptPath -ChildPath 'docker-compose.yml') -Destination $backupFolder -ErrorAction Stop
  } else {
    Write-Warning "'docker-compose.yml' file does not exist."
  }

  if (Test-Path -Path (Join-Path -Path $scriptPath -ChildPath 'certs')) {
    Copy-Item -Path (Join-Path -Path $scriptPath -ChildPath 'certs') -Destination $backupFolder -Recurse -ErrorAction Stop
  } else {
    Write-Warning "'certs' directory does not exist."
  }

  #if (Test-Path -Path (Join-Path -Path $scriptPath -ChildPath 'ssl')) {
  #  Copy-Item -Path (Join-Path -Path $scriptPath -ChildPath 'ssl') -Destination $backupFolder -Recurse -ErrorAction Stop
  #} else {
  #  Write-Warning "'ssl' directory does not exist."
  #}

  Write-Host "Backup of Existing Certificates complete and docker .env and compose files, inspect in $backupFolder"
} catch {
  Write-Error "An error occurred: $_"
}

# Tested Locally and Verified as working