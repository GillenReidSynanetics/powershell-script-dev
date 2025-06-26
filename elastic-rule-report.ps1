
# Documentation is here - https://www.elastic.co/docs/api/doc/kibana/v8/group/endpoint-alerting
# This block of code stores variables for the output file, API credentials, and base URL.
# The script retrieves alerting rules from the Elastic API and checks for scheduling issues.
# It compares the schedule interval and time window size of the rules, logging any mismatches to a CSV file.
# The script also handles errors during the API call and creates the output file if it doesn't exist.

$ODS = Read-Host -Prompt "Please enter your ODS to search (ensure in CAPS e.g. 'RCU')"

$outputFile = "$env:USERPROFILE\Desktop\Generated-Rule-Report1.csv"
$Username = "synanetics-system"
$Password = "Kc1cmCxYDG^bP@cMDP5u"
$credentials = "$($Username):$($Password)"
$credentialBytes = [System.Text.Encoding]::ASCII.GetBytes($credentials)
$EncodedCredentials = [System.Convert]::ToBase64String($credentialBytes)
$baseUrl = "https://elastic-production.kb.europe-west2.gcp.elastic-cloud.com/s/synanetics/api/alerting/rules/_find?per_page=1000"
$pageQuery = "&filter=alert.attributes.tags:$ODS"
$uri = "$baseUrl"

# This block of code constructs the API request headers and makes the API call to retrieve alerting rules.

$headers = @{
    Authorization         = "Basic $($EncodedCredentials)"
    "kbn-xsrf"            = "true"
    "content-type"        = "application/json"
    "elastic-api-version" = "2023-10-31"
}

# This block of code includeds error handling for the API call and the actual API call itself, additionally it checks if the output file already exists and creates it if it does not.
try {
    $response = Invoke-RestMethod -Uri "$uri$pageQuery" -Method Get -Headers $headers
}
catch {
    Write-Error "Failed to make API call: $_"
    exit 1
}

if (-not (Test-Path -Path $outputFile)) {
    Write-Output "Creating report file at $outputFile"
    New-Item -Path $outputFile -ItemType File -Force
}
else {
    Write-Output "Log file already exists at $outputFile"
}

# Performs query and converts to JSON - generates and outputs to terminal - potentially provide flexibility to REST method?

$response = Invoke-RestMethod -Uri "$uri$pageQuery" -Method Get  -Headers $headers 
$jsonOutput = $response | ConvertTo-Json -Depth 10
$jsonOutput

# This block of code compares the schedule interval and time window size of the retrieved rules and logs any mismatches to the CSV file.
# Small workaround to get the time window size and unit to be in the same format as the schedule interval as this time was presented in 2 separate fields.


foreach ($item in $response.data) {
    $timeA = $item.params.timeWindowSize
    $timeB = $item.params.timeWindowUnit
    $mergedTime = "$timeA$timeB"
    write-host $mergedTime
    

    if ($item.schedule.interval -ne $mergedTime) { # Can add an additional check wether rule is enabled as a number have been disabled and do not need to be checked
        Write-Host "Scheduling issue, please review these rules and resolve $($item.name)" -ForegroundColor Green
        $item | Select-Object name, schedule, params, id, enabled | Export-Csv -Path "$outputFile" -Append -NoTypeInformation -Force
    }
    else {
        Write-Host "No issues found"
    }
}

#=======================================================================================================================================================================




