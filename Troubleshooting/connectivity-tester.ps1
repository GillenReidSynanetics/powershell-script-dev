<#
.SYNOPSIS
    Tests network connectivity to a specified endpoint and logs the results.

.DESCRIPTION
    Prompts the user to enter an IP address or hostname, then performs a ping test (Test-Connection) to the specified endpoint.
    If the ping is successful, displays the results and runs a traceroute (Test-NetConnection -TraceRoute).
    The results of the ping test are exported to a CSV file on the user's Desktop (ConnectivityResult.csv).
    If the CSV file does not exist, it is created.

.PARAMETER endpointIP
    The IP address or hostname of the endpoint to test connectivity with. Entered by the user at runtime.

.OUTPUTS
    Writes ping and traceroute results to the console.
    Appends ping test results to a CSV file on the Desktop.

.NOTES
    Author: Gillen Reid
    File: connectivity-tester.ps1
    Requires: PowerShell 5.1 or later

.EXAMPLE
    PS> .\connectivity-tester.ps1
    Enter the IP address or hostname of the endpoint you want to test:
    8.8.8.8

    This will test connectivity to 8.8.8.8, display results, run a traceroute, and log the ping results to ConnectivityResult.csv.
#>
Write-Host "Enter the IP address or hostname of the endpoint you want to test:" -ForegroundColor Green
$endpointIP = Read-Host
$csvOutput = "$env:USERPROFILE\Desktop\ConnectivityResult.csv"
$result = Test-Connection -ComputerName $endpointIP -Count 4 -ErrorAction SilentlyContinue 

if (-not (Test-Path -Path $csvOutput)) {
    New-Item -ItemType File -Path $csvOutput -Force
}

if ($result) {
    $result
    Write-Host "Ping to $endpointIP was successful." -ForegroundColor Green
    Write-Host "Running traceroute to $endpointIP..." -ForegroundColor Green
    Test-NetConnection -ComputerName $endpointIP -TraceRoute
} else {
    Write-Host "Ping to $endpointIP failed." -ForegroundColor Red
}

$result | Export-Csv -Path $csvOutput -NoTypeInformation -Encoding UTF8 -Append
write-host "Ping results have been logged to $csvOutput" -ForegroundColor Yellow
read-host "Press Enter to exit"
exit
# End of connectivity-tester.ps1