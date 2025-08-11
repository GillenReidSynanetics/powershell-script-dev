<#
.SYNOPSIS
    Script to clean up the WinSxS folder and perform system maintenance tasks.

.DESCRIPTION
    This script performs a series of maintenance tasks to clean up the WinSxS folder and other temporary files on a Windows system. 
    It logs all actions to a specified log file and restarts the computer to apply changes.

.PARAMETER logFile
    The path to the log file where all actions will be logged.

.FUNCTIONS
    logmessage
        Logs a message with a timestamp to the log file.

.EXAMPLE
    .\winsxs_cleanup.ps1
    Runs the script to clean up the WinSxS folder and perform system maintenance tasks.

#>
param (
    [string]$logFile = "C:\Windows\Logs\winsxs_cleanup.log"
)

function logmessage {
    param ([string]$message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logentry = "$timestamp - $message"
    Write-Output $logentry | Tee-Object -FilePath $logFile -Append
}

function runDismCommand {
    param ([string]$command)
    logmessage "Running $command..."
    Invoke-Expression $command | Tee-Object -FilePath $logFile -Append
}

logmessage "Starting winsxs cleanup"
logmessage "Checking current WinSxS size..."
runDismCommand "dism /online /cleanup-image /analyzecomponentstore"

runDismCommand "Dism.exe /online /Cleanup-Image /StartComponentCleanup"
runDismCommand "Dism.exe /online /Cleanup-Image /SPSuperseded"
runDismCommand "dism /online /cleanup-image /startcomponentcleanup /SPSuperseded"

logmessage "Running Disk Cleanup..."
cleanmgr.exe /sagerun:1 | Tee-Object -FilePath $logFile -Append

logmessage "Deleting CBS logs..."
Remove-Item -Path "C:\Windows\Logs\CBS\*" -Force | Tee-Object -FilePath $logFile -Append

logmessage "Deleting Temp files..."
Remove-Item -Path "C:\Windows\Temp\*" -Force -Recurse | Tee-Object -FilePath $logFile -Append

logmessage "Removing unused features..."
dism /online /get-features | ForEach-Object {
    if ($_ -match "Disabled") {
        $featureName = ($_ -split ": ")[1].Trim()
        logmessage "Removing $featureName..."
        runDismCommand "dism /online /disable-feature /featurename:$featureName"
    }
}

logmessage "Checking WinSxS size after cleanup..."
runDismCommand "Dism /Online /Cleanup-Image /AnalyzeComponentStore"

logmessage "Restarting computer to apply changes..."
Restart-Computer -Force
