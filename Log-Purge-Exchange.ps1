<#
.SYNOPSIS
    This script purges specific log files related to SQL Exchange operations.

.DESCRIPTION
    The script attempts to delete a predefined list of log files located in the "C:\Synanetics\SQL\" directory.
    If any of the specified log files exist, they will be removed. The script handles any errors that occur during
    the deletion process and outputs an error message if an exception is caught. Upon completion, a message is displayed
    indicating that the cleanup script execution is completed.

.NOTES
    File Name  : Log-Purge-Exchange.ps1
    Author     : Mark Bain
    Date       : <Insert Date>
    Version    : 1.0

.EXAMPLE
    To execute the script, simply run it in a PowerShell session:
    .\Log-Purge-Exchange.ps1

#>
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

try {
    Clear-Host
    $Logs = @(
        "C:\Synanetics\SQL\EXCHANGE_TotalInbound.log"
        "C:\Synanetics\SQL\EXCHANGE_TotalInbound_Unsupported.log"
        "C:\Synanetics\SQL\RTGXCH_TotalInbound.log"
        "C:\Synanetics\SQL\RTGXCH_TotalInbound_Unsupported.log"
        "C:\Synanetics\SQL\EXCHANGE_TotalInbound_today.log"
        "C:\Synanetics\SQL\EXCHANGE_TotalInbound_today_Unsupported.log"
        "C:\Synanetics\SQL\RTGXCH_TotalInbound_today.log"
        "C:\Synanetics\SQL\RTGXCH_TotalInbound_today_Unsupported.log"
    )

    ForEach ($Log in $Logs) {
        if (Test-Path $Log) {Remove-Item $Log}
    }

} catch {
    Write-Error "-----------------------ERROR---------------------------"
    Write-Error $_
    Write-Error "-------------------------------------------------------"
} Finally {
    Write-Host "Cleanup script execution completed."
}