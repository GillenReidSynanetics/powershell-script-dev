

$logfilepath = ""
$csvOutput = "$env:USERPROFILE\Desktop\CalculationOutput.csv"


if (-not (Test-Path -Path $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath -Force
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

    [PSCustomObject]@{
        LogFileName          = [System.IO.Path]::GetFileName($logFilePath) + " - name here"
        AverageTimeInSeconds = $averageSeconds
        TotalMessages        = $timestamps.Count
    } | Export-Csv -Path $csvOutput -NoTypeInformation -Encoding UTF8 -Append

}
else {
    Write-Output "Not enough messages to calculate time differences."
}







