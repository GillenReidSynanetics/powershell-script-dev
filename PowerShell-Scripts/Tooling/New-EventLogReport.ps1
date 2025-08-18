# Notes on adjustments:

# Level | Meaning
# 1 | Critical
# 2 | Error
# 3 | Warning
# 4 | Information
# 5 | Verbose

# $startTime = (Get-Date).AddDays(-7) 
# Currently set to 7 days, change to -1 for 24 hours, -30 for 30 days, etc.

# Lognames
# Application, Security, Setup, System, ForwardedEvents
# For more information on event logs, see: https://learn.microsoft.com/en-us/windows/win32/wes/understanding-event-logs-and-event-log-records


Write-Host "Starting Event Viewer script..." -ForegroundColor Yellow

# Variables for storage
$logname = "Application" # Default log name to extract events from
$startTime = (Get-Date).AddDays(-14) # Default start time for event extraction, 7 days ago - adjust as needed
$htmlPath = "$ENVPROFILE\Desktop\event_viewer.html" # Path to save the HTML report
$eventIDs = @(1000, 7001, 1001)  # Custom list
# of event IDs to filter, if needed


# Error handling for missing html

if (-not (Test-Path $htmlPath)) {
    Write-Host "HTML File not found, generating..." -ForegroundColor Yellow
    New-Item -Path $htmlPath -ItemType File -Force | Out-Null
}
 
# Styling for the HTML report to make it more presentable.

$css = @"
<style>
    body { font-family: Segoe UI, sans-serif; margin: 20px; }
    h2 { color: #2e6c80; }
    table { width: 100%; border-collapse: collapse; margin-top: 15px; }
    th, td { padding: 10px; border: 1px solid #ddd; text-align: left; vertical-align: top; }
    th { background-color: #f2f2f2; }
    tr:nth-child(even) { background-color: #fafafa; }
    tr:hover { background-color: #e6f7ff; }
</style>
"@

# Function to retrieve logs 

$events = Get-WinEvent -FilterHashtable @{
    LogName = $logname
    StartTime = $startTime
    level = 2, 3 # Error and Warning levels
    Id = $eventIDs # Custom event IDs to filter
} | Select-Object TimeCreated, LevelDisplayName, Id, ProviderName, Message


# Integrates CSS into alongside generating the report
$html = $events | ConvertTo-Html -Title "Event Log Report ($logName)" `
    -PreContent "<h2>Event Log Report – $logName<br/>From $($startTime.ToString('g')) to $(Get-Date -Format g)</h2>$css"

# Function to convert event data to HTML
$html | Out-File -FilePath $htmlPath -Encoding utf8 -Force

# Automatically kick off broswer to open the HTML report
Start-Process $htmlPath


