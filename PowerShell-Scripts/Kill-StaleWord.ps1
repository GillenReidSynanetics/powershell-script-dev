<#
.SYNOPSIS
    Terminates all instances of 'winword.exe' (Microsoft Word) that have been running longer than a specified number of minutes.

.DESCRIPTION
    This script searches for all running instances of the 'winword.exe' process. It identifies those that have been running longer than a user-defined threshold (default: 10 minutes) and terminates them automatically. The script provides user feedback throughout its execution, including the number of processes found, which ones are considered stale, and the outcome of the termination attempt.

.PARAMETER processName
    The name of the process to search for and terminate if stale. Default is 'winword.exe'.

.PARAMETER olderThanMinutes
    The age threshold in minutes. Processes older than this value will be terminated. Default is 10 minutes.

.NOTES
    Author: Gillen Reid
    File: KillRogueWord 1.ps1

.EXAMPLE
    .\KillRogueWord 1.ps1

    Runs the script to terminate all 'winword.exe' processes older than 10 minutes.

#>

$processName = "winword.exe"
$olderThanMinutes = 10

Write-Host "This script will kill all instances of $processName that are older than $olderThanMinutes minutes."
1..5 | ForEach-Object {
    Write-Host "Processing in $_ seconds..."
    Start-Sleep -Seconds 1
    write-host "'r" -NoNewline
}

Write-Host "Starting to check for processes..."

# --- Find Stale Processes ---
Write-Host "`nSearching for '$processName' processes..." -ForegroundColor Cyan

try {
    $allProcesses = Get-Process -Name $processName -ErrorAction Stop
}
catch {
    Write-Warning "No processes found with the name '$processName'."
    Read-Host "Press Enter to exit."
    exit
}

$thresholdTime = (Get-Date).AddMinutes(-$olderThanMinutes)
$staleProcesses = $allProcesses | Where-Object { $_.StartTime -lt $thresholdTime }

# --- Report Findings and Take Action ---
Write-Host "$($allProcesses.Count) '$processName' process(es) found."

if (-not $staleProcesses) {
    Write-Host "No stale processes found to stop." -ForegroundColor Green
}
else {
    Write-Warning "$($staleProcesses.Count) stale process(es) will be stopped automatically."
    $staleProcesses | Format-Table Id, StartTime, ProcessName

    try {
        $staleProcesses | Stop-Process -Force -ErrorAction Stop
        Write-Host "✅ Successfully stopped $($staleProcesses.Count) processes." -ForegroundColor Green
    }
    catch {
        Write-Error "❌ An error occurred while stopping processes. Details: $($_.Exception.Message)"
    }
}

Read-Host "`nPress Enter to exit."
