<#
.SYNOPSIS
    Parses a log file for lines containing 'ERROR' or 'WARNING' and exports the results to a CSV file.

.DESCRIPTION
    This script prompts the user for a CSV output file name, searches a specified log file for lines containing
    the keywords 'ERROR' or 'WARNING', and attempts to parse each matching line for timestamp, log level, and message.
    The results are exported to a CSV file on the user's Desktop. If a matching line does not fit the expected format,
    it is still included in the output with a note indicating parsing failure.

.PARAMETER logFilePath
    The path to the log file to be analyzed. Update this variable with the actual path to your log file.

.PARAMETER csvFileName
    The base name for the output CSV file (without extension), prompted from the user.

.PARAMETER csvOutputPath
    The full path to the output CSV file, constructed using the user's Desktop and the provided file name.

.PARAMETER pattern
    The regular expression pattern used to identify lines of interest (default: 'ERROR|WARNING').

.INPUTS
    None. The script prompts the user for input.

.OUTPUTS
    A CSV file containing the parsed log entries with columns: Timestamp, Level, and Message.

.NOTES
    - The script expects log lines in the format: 'YYYY-MM-DD HH:MM:SS [LEVEL] Message'.
    - Lines that match the pattern but not the expected format are still included in the CSV with a parsing note.
    - If no matching lines are found, a success message is displayed and no CSV is created.

.EXAMPLE
    # Run the script and follow the prompts to generate a CSV report of errors and warnings from a log file.
#>
$logFilePath = " add the path to your log file here, e.g., C:\path\to\your\logfile.log"
$csvFileName = Read-Host "Please enter file name for the CSV output (without extension)"


$csvOutputPath = "env:USERPROFILE\Desktop\$fileName.csv" # Define the path to the log file and the output CSV file
$pattern = 'ERROR|WARNING' # Define the error capture patterns here


if (-not (Test-Path -Path $logFilePath)) {
    Write-Error "Log file does not exist at the specified path: $logFilePath"
    Read-Host "Press Enter to exit"
    return
}

Write-Host "Searching for lines containing '$pattern' in $logFilePath..." -ForegroundColor Yellow

# --- Processing ---
# Efficiently capture all matching lines and their data in one go.
$errorEntries = Get-Content -Path $logFilePath | ForEach-Object {
    $line = $_

    # Fast check using the combined regex pattern.
    if ($line -match $pattern) {
        
        # This regex assumes a format like 'YYYY-MM-DD HH:MM:SS [LEVEL] Message'
        # It uses named capture groups to easily grab the data.
        $regex = '^(?<timestamp>\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}:\d{2})\s\[(?<level>\w+)\]\s(?<message>.*)$'

        if ($line -match $regex) {
            # Create a structured object with data parsed from the line.
            [PSCustomObject]@{
                Timestamp = $Matches.timestamp
                Level     = $Matches.level
                Message   = $Matches.message
            }
        }
        else {
            # If a line has a keyword but doesn't match the format, save it as-is.
            [PSCustomObject]@{
                Timestamp = 'COULD NOT PARSE'
                Level     = 'N/A'
                Message   = $line
            }
        }
    }
}

# --- Output Results ---
if ($errorEntries.Count -eq 0) {
    Write-Host "Success! No lines matching '$pattern' were found." -ForegroundColor Green
} else {
    try {
        # Export the collected data to the CSV file.
        $errorEntries | Export-Csv -Path $csvOutputPath -NoTypeInformation -Encoding UTF8
        Write-Host "Success! Found $($errorEntries.Count) matching entries." -ForegroundColor Green
        Write-Host "Report saved to: $csvOutputPath"
    }
    catch {
        Write-Error "Could not save the CSV file. Error: $_"
    }
}

Read-Host "Press Enter to exit"