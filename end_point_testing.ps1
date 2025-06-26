
# Variables including localization of search path and file name
$envFilePath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$envFilePath = ".env"

# error handling for file not found
if (-not (Test-Path $envFilePath)) {
    Write-Host "Environment file not found"
    exit 1
}

# Search for the file in the current directory
$envContent = Get-Content $envFilePath  | Where-Object { $_ -match "^(?!#)(.+?)=(http[s]?:\/\/.+)$" }

$endpoints = @()
foreach ($line in $envContent) {
    if ($line -match "^(.+?)=(http[s]?:\/\/.+)$") {
        $key = $matches[1].Trim()
        $url = $matches[2].Trim()
        $endpoints[$key] = $url
    }
}

# Store Results
$results = @()

# Loop through each endpoint and test the connection

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


Write-Host $results | Format-Table -AutoSize
Write-Host "Task complete - Please press enter to close"
Read-Host
