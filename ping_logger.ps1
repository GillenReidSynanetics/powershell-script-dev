<#
.SYNOPSIS
    This script pings a specified IP address and logs the results to a file for further inspection.

.DESCRIPTION
    The script prompts the user to enter an IP address and verifies its format. It then asks for a path to save the log file, defaulting to the current directory if none is provided. The script performs a ping test to the specified IP address, calculates the average response time, and logs the results with detailed information including timestamp, IP address, status, and ping details.

.PARAMETER ipAddress
    The IP address to ping, entered by the user.

.PARAMETER logPath
    The path where the ping log file will be saved. If not provided, the log file will be saved in the current directory with the name "ping_log.txt".

.EXAMPLE
    PS> .\ping-logger.ps1
    Enter the IP address you want to ping: 8.8.8.8
    Enter the path to save the ping log file (or press Enter for current directory):
    Performing ping test...
    Ping Result saved to log file, txt file should be in same directory - attach to ticket for inspection 'C:\path\to\current\directory\ping_log.txt'

.NOTES
    Made by Gillen
#>

# User prompted for IP address.
$ipAddress = Read-Host "Enter the IP address you want to ping"

# Verify IP address is correct format for processing.
if ($ipAddress -notmatch '^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
    Write-Host "Invalid IP address format. Please enter a valid IP address." -ForegroundColor Red
    return
}

# Always press enter at this stage, as it will save the log file in the same directory as where the script is.
$logPath = Read-Host "Enter the path to save the ping log file (or press Enter for current directory)"
if (-not $logPath) {
    $logPath = Join-Path (Get-Location) "ping_log.txt" 
}

# Ping test firing
Write-Host "Performing ping test..."

try {
    # Create an array to store ping results
    $pingResults = Test-Connection -ComputerName $ipAddress -Count 4 -ErrorAction Stop

    # Calculate statistics
    $averagePing = $pingResults | Measure-Object -Property ResponseTime -Average

    # Determine the status
    $status = if ($pingResults[0].StatusCode -eq 0) { "Success" } else { "Failed" }

    # Format the ping details
    $pingDetails = $pingResults | ForEach-Object {
        "Reply from $($_.Address): bytes=$($_.BufferSize) time=$($_.ResponseTime)ms TTL=$($_.TimeToLive)"
    } | Out-String

    # Write to log file with enhanced formatting
    $logEntry = @"
-------------------------------------------
Timestamp:     $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
IP Address:    $ipAddress
Status:        $status
-------------------------------------------
Ping Details:
$pingDetails
-------------------------------------------
Average Ping:  $([math]::Round($averagePing.Average, 2)) ms
-------------------------------------------

"@

    Add-Content $logPath $logEntry

    Write-Host "Ping Result saved to log file, txt file should be in same directory - attach to ticket for inspection '$logPath'" -ForegroundColor Green
} catch {
    Write-Host "An error occurred during the ping test: $_" -ForegroundColor Red
}