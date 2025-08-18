<#
.SYNOPSIS
    Automates system clean up by clearing the recycle bin and running disk cleanup.

.DESCRIPTION
    This script prompts the user for confirmation before proceeding to clear the recycle bin and perform an automated disk cleanup using Windows built-in utilities. It sets the necessary registry flags for disk cleanup and executes 'cleanmgr.exe' with predefined settings.

.PARAMETER None
    The script does not accept any parameters. User interaction is required for confirmation.

.NOTES
    - Requires administrative privileges to modify registry and run disk cleanup.
    - Tested on Windows environments with PowerShell.
    - Registry path: HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches

.EXAMPLE
    PS C:\> .\clean_up_v3.ps1
    Prompts for confirmation, then clears recycle bin and runs disk cleanup if confirmed.

#>
Write-Host "Starting system clean up script..."
Write-Host "This script will clear recycle bin and run an automated disk clean up."
$confirmation = Read-Host "Do you want to proceed? (Y/N)"

if ($confirmation -ne 'Y') {
    write-host "Exiting script."
    start-sleep -Seconds 2
    exit
}

try {
    write-host "Clearing recycle bin..."
    clear-recyclebin -Force -ErrorAction Stop
    Write-Host "Recycle bin cleared successfully." -ForegroundColor Green

    write-host "Running disk cleanup..."

    $regpath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
    Get-ChildItem -Path $regpath | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "StateFlags" -Value 2 -ErrorAction SilentlyContinue
    }

    Start-Process cleanmgr.exe -ArgumentList "/sagerun:1" -Wait -NoNewWindow
    Write-Host "Disk cleanup completed successfully." -ForegroundColor Green
}
catch {
    Write-Error "An unexpected error occurred during the cleanup process: $_"


}

finally {
    Write-Host "System clean up script completed."
    Write-Host "Please check the results and ensure your system is optimized." -ForegroundColor Yellow
    Start-Sleep -Seconds 2
    exit
}