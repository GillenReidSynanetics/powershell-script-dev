
# I recently discovered the possibility of live monitoring of output, so the idea is to take a look at the live output, powershell does not have a stream monitor
# but it does have a way to monitor the output of a file, so I will use that to monitor the output of the docker logs command.
# mainly going to use get-content -wait -tail 10 to monitor the output of the docker logs command, and then filter the output for errors and warnings.
# I will also use the -match operator to filter the output for errors and warnings, and then export the output to a csv file.


# This script filters a log file for specific error or warning lines and exports them to a CSV file.
# The format it monitors is the JSON logging driver only, other logging drivers will not work with this script due to formatting.

# === Configuration ===
$logFilePath = Read-Host "Enter the full path to the log file"
$csvOutput = "$env:USERPROFILE\Desktop\live-error-capture.csv"
$errorCapture = @("ERROR", "WARNING")
$script:lastMatchTime = Get-Date  # Must be in script scope for the heartbeat

# === Create CSV header if needed ===
if (-not (Test-Path -Path $csvOutput)) {
    [PSCustomObject]@{
        Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
        LogLine   = "No error or warning lines found in the log file."
    } | Export-Csv -Path $csvOutput -NoTypeInformation -Encoding UTF8
}

Write-Host "Monitoring log file for error/warning lines - will append to $csvOutput" -ForegroundColor Yellow

# === Heartbeat Timer Setup ===
$heartbeatTimer = New-Object Timers.Timer
$heartbeatTimer.Interval = 30000
$heartbeatTimer.AutoReset = $true
$heartbeatTimer.Enabled = $true

Register-ObjectEvent -InputObject $heartbeatTimer -EventName Elapsed -SourceIdentifier HeartbeatTimer -Action {
    $now = Get-Date
    if (($now - $using:lastMatchTime).TotalSeconds -ge 30) {
        Write-Host "[$($now.ToString("yyyy-MM-dd HH:mm:ss"))] No new matches found in the last 30 seconds." -ForegroundColor Green
    }
} | Out-Null

# === Start Log Monitoring ===
try {
    Get-Content -Path $logFilePath -Wait -Tail 0 | ForEach-Object {
        $line = $_

        if ($errorCapture | Where-Object { $line -match "(?i)$_" }) {
            $entry = [PSCustomObject]@{
                Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
                LogLine   = $line
            }

            $entry | Export-Csv -Path $csvOutput -NoTypeInformation -Encoding UTF8 -Append
            Write-Host "[$($entry.Timestamp)] Match: $line" -ForegroundColor Red

            $script:lastMatchTime = Get-Date
        }
    }
}
finally {
    # Cleanup
    Unregister-Event -SourceIdentifier HeartbeatTimer
    $heartbeatTimer.Dispose()
    Write-Host "Monitoring stopped and resources cleaned up." -ForegroundColor Cyan
}










# Get-Content -path $logFilePath | ForEach-Object {
#     $line = $_

#     if ($errorCapture | Where-Object { $line -match $_ }) {
#         $errorEntries += [PSCustomObject]@{
#             Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
#             LogLine   = $line
#         }
#     }
# }


# if ($errorEntries.Count -eq 0) {
#     Write-Host "No error or warning lines found in the log file." -ForegroundColor Green
#     return
# } else {
#     $errorEntries | Export-Csv -Path $csvOutput -NoTypeInformation -Encoding UTF8
# }

# Write-Host "Filtered error lines written to: $csvOutput"



# $logFilePath = Read-Host "Enter the full path to the log file"
# $csvOutput = "$env:USERPROFILE\Desktop\live_errors.csv"
# $errorCapture = @("ERROR", "WARNING")

# # Ensure log file exists
# if (-not (Test-Path -Path $logFilePath)) {
#     Write-Host "Log file not found at path: $logFilePath" -ForegroundColor Red
#     return
# }

# # Create CSV file if it doesn't exist
# if (-not (Test-Path -Path $csvOutput)) {
#     "" | Out-File -FilePath $csvOutput
# }

# # Start monitoring
# Write-Host "Monitoring log file for ERRORs and WARNINGs..." -ForegroundColor Yellow

# Get-Content -Path $logFilePath -Wait -Tail 0 | ForEach-Object {
#     $line = $_

#     if ($errorCapture | Where-Object { $line -match "(?i)$_" }) {
#         $entry = [PSCustomObject]@{
#             Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
#             LogLine   = $line
#         }

#         # Append to CSV
#         $entry | Export-Csv -Path $csvOutput -NoTypeInformation -Encoding UTF8 -Append
#         Write-Host "[$($entry.Timestamp)] Match: $line" -ForegroundColor Red
#     }
# }
