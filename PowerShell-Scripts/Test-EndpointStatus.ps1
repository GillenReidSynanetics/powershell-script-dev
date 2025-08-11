<#
.SYNOPSIS
    Script to test the availability of endpoints defined in an environment file.

.DESCRIPTION
    This script reads an environment file (.env) to extract endpoint URLs and tests their availability using HTTP GET requests.
    It outputs the status and HTTP response code for each endpoint.

.PARAMETERS
    None

.EXAMPLE
    .\end-point.ps1
    This will execute the script and test the endpoints defined in the .env file located in the same directory as the script.

.NOTES
    The environment file should contain key-value pairs in the format KEY=URL, where URL is the endpoint to be tested.
    Lines starting with '#' are treated as comments and ignored.

.OUTPUTS
    A table displaying the endpoint key, URL, status (OK/FAILED), and HTTP response code.

#>


$scriptFilePath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$envFilePath = Join-Path -Path $scriptFilePath -ChildPath ".env"

if (-not (Test-Path $envFilePath)) {
    Write-Host "Environment file not found"
    Read-Host "Press enter to exit"
    exit 1
}

$envContent = Get-Content $envFilePath  | Where-Object { $_ -match "^(?!#)(.+?)=(http[s]?:\/\/.+)$" }
$endpoints = @{}

foreach ($line in $envContent) {
    if ($line -match "^(.+?)=(http[s]?:\/\/.+)$") {
        $key = $matches[1].Trim()
        $url = $matches[2].Trim()
        $endpoints[$key] = $url
    }
}


$results = @()
foreach ($key in $endpoints.Keys) {
    $url = $endpoints[$key]
    Write-Host "Testing $key -> $url"
    
    try {
        $response = Invoke-WebRequest -Uri $url -Method Get -TimeoutSec 5 -ErrorAction Stop
        $status = "OK"
        $httpCode = $response.StatusCode
    }
    catch {
        $status = "FAILED"
        $httpCode = $_.Exception.Response.StatusCode.value__
    }

    # Store results
    $results += [PSCustomObject]@{
        Endpoint = $key
        URL      = $url
        Status   = $status
        HTTPCode = $httpCode
    }
}


$results | Format-Table -AutoSize
