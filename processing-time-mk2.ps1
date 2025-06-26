# Variables and array to capture information

Import-Module ImportExcel

$logfilepath = "C:\Users\GillenReid\OneDrive - synanetics.com\Desktop\c6c6abcbd73838bc8762fde9f48be2ad701e5ef4e5eced48a0c34d746c091440-json.log\c6c6abcbd73838bc8762fde9f48be2ad701e5ef4e5eced48a0c34d746c091440-json.log.txt"
$excelOutput = "$env:USERPROFILE\Desktop\PivotReport.xlsx"

if (-not (Test-Path -Path $excelOutput)) {
    New-Item -ItemType File -Path $excelOutput -Force
}

# Read the log file
$lines = Get-Content -Path $logfilepath

$timestamps = @()

# Look for lines with "New message received" and extract ISO timestamps
foreach ($line in $lines) {
    if ($line -match "MESSAGEREADER: New message received" -and $line -match '"time":"([^"]+)"') {
        $timestampStr = $matches[1]
        try {
            $dt = [datetime]::Parse($timestampStr)
            $timestamps += $dt
        }
        catch {
            Write-Warning "Failed to parse: $timestampStr"
        }
    }
}

# Calculate time differences
for ($i = 1; $i -lt $timestamps.Count; $i++) {
    $start = $timestamps[$i - 1]
    $end = $timestamps[$i]
    $delta = $end - $start

    Write-Output "Message $($i - 1) to $i{}: $($delta.TotalSeconds) seconds"
}

if ($timestamps.Count -gt 1) {
    $totalSeconds = 0
    for ($i = 1; $i -lt $timestamps.Count; $i++) {
        $totalSeconds += ($timestamps[$i] - $timestamps[$i - 1]).TotalSeconds
    }
    $averageSeconds = $totalSeconds / ($timestamps.Count - 1)
    Write-Output "Average time between messages: $averageSeconds seconds"

    $data = @(
        [PSCustomObject]@{
            LogFileName          = [System.IO.Path]::GetFileName($logFilePath) + " - Test Data Table "
            AverageTimeInSeconds = $averageSeconds
            TotalMessages        = $timestamps.Count
        }
    )

    $data | Export-Excel -Path $excelOutput -AutoNameRange -Show -PivotRows $averageSeconds -PivotColumns $totalSeconds -PivotData $timestamps.Count -WorksheetName "Summary" -TableName "SummaryTable" -AutoSize
    Write-Host "Pivot Table Generated and saved to $excelOutput"

}
else {
    Write-Output "Not enough messages to calculate time differences."
}