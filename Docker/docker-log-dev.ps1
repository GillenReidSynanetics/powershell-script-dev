

<#
.SYNOPSIS
    Filters error and warning lines from a specified log file and exports them to a CSV file.

.DESCRIPTION
    This script prompts the user for a CSV output file name, reads a specified log file, and searches for lines containing "ERROR" or "WARNING".
    Matching lines are collected with a timestamp and exported to a CSV file on the user's Desktop.
    If no matching lines are found, a message is displayed.

.PARAMETER fileName
    The base name (without extension) for the output CSV file. The user is prompted to enter this value.

.PARAMETER logFilePath
    The path to the log file to be scanned for error and warning entries. This must be set in the script.

.PARAMETER csvOutput
    The full path to the output CSV file, constructed from the user's Desktop path and the provided file name.

.NOTES
    - The script creates the log file if it does not exist.
    - The error patterns to capture can be modified in the $errorCapture array.
    - Each matching log line is exported with the current timestamp and the log content.

.EXAMPLE
    # Run the script and follow the prompt to enter a file name for the CSV output.
    # The script will process the specified log file and export error/warning lines to the Desktop.
#>


$fileName = Read-Host "Please enter file name for the CSV output (without extension)"
$logFilePath = " add the path to your log file here, e.g., C:\path\to\your\logfile.log"
$csvOutput = "$env:USERPROFILE\Desktop\$fileName.csv" # Define the path to the log file and the output CSV file
$errorCapture = @("ERROR", "WARNING") # Define the error capture patterns here
$errorEntries = @() # Initialize an array to hold error entries
# Ensure the log file exists
if (-not (Test-Path -Path $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath -Force
}

Get-Content -path $logFilePath | ForEach-Object {
    $line = $_

    if ($errorCapture | Where-Object { $line -match $_ }) {
        $errorEntries += [PSCustomObject]@{
            Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
            LogLine   = $line
        }
    }
}


if ($errorEntries.Count -eq 0) {
    Write-Host "No error or warning lines found in the log file." -ForegroundColor Green
    return
} else {
    $errorEntries | Export-Csv -Path $csvOutput -NoTypeInformation -Encoding UTF8
}

Write-Host "Filtered error lines written to: $csvOutput"