
# Self-contained PowerShell script to gather system metrics and send them to Elasticsearch
# This script is designed to run on a local machine and send metrics to a specified Elasticsearch index
# Further options down the line could include more metrics, such as network usage, process counts, etc.
# Ensure the script is run with appropriate permissions to access system metrics and Elasticsearch
# Potentially using this to deploy to a azure function app or similar service for production usage?
# Scenario is where clients are obstucting access/refusing deployment of agents
# test platform connection to Elasticsearch - integrate log posting to elasticsearch
# Configuration for Elasticsearch connection
# to do - encrupt the password and use a secure method to store credentials
# Ideas for testing more metrics can be added later

$esUri = "https://localhost:9200/local-machine-test/_doc/f6276f8d-7eba-4991-8945-7910c31e77bd" # formatting ideas for the URI to identify the machine and document?
$apiKey = "your_api_key_here" # Replace with your actual API key if needed
$logTimeframeHours = 24 # Define the timeframe for log analysis in hours
$piiRegex = '\b\d{3}\s?\d{3}\s?\d{4}\b'
$redactionText = '[REDACTED_NHS_NUMBER]'

write-host "Deploying headers for Elasticsearch connection..."

$headers = @{
    Authorization = "Basic $($EncodedCredentials)"
    "Content-Type" = "application/json"
} # Define the content type as JSON for the request


$timestamp = Get-Date -Format "yyyy.MM.dd-HH-mm-ss"
$indexName = "temp docker logs-$timestamp"
write-host "generated unique index name: $indexName"


$endtime = Get-Date
$startTime = $endtime.AddHours(-$logTimeframeHours)
$dockerSinceTime = $startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
Write-Host "Gathering logs from Docker containers since $dockerSinceTime"

$indexMapping = @{
    mappings = @{
        properties = @{
            "@timestamp"     = @{ type = "date" }
            "container_name" = @{ type = "keyword" }
            "container_id"   = @{ type = "keyword" }
            "log_level"      = @{ type = "keyword" } # Example: if you can parse a level
            "message"        = @{ type = "text" }
        }
    }
} | ConvertTo-Json -Depth 5

try {
    $elasticParams = @{
        Uri         = "$elasticUrl/$indexName"
        Method      = 'PUT'
        Headers     = $headers
        Body        = $indexMapping
        ContentType = 'application/json'
    }
    # Use credential if defined
    if ($credential) { $elasticParams.Credential = $credential }
    
    Invoke-RestMethod @elasticParams -ErrorAction Stop
    Write-Host -ForegroundColor Green "Successfully created Elasticsearch index '$indexName'."
}
catch {
    Write-Error "Failed to create Elasticsearch index. Response: $($_.Exception.Response.Content | Out-String)"
    exit 1
}

# --- 4. Create Kibana Data View ---
Write-Host "Creating Kibana data view..."

$dataViewPayload = @{
    data_view = @{
        title = $indexName
        name  = $indexName
        timeFieldName = "@timestamp"
    }
} | ConvertTo-Json -Depth 3

try {
    $kibanaParams = @{
        Uri         = "$kibanaUrl/api/data_views/data_view"
        Method      = 'POST'
        Headers     = $headers
        Body        = $dataViewPayload
        ContentType = 'application/json'
    }
    # Use credential if defined
    if ($credential) { $kibanaParams.Credential = $credential }

    Invoke-RestMethod @kibanaParams -ErrorAction Stop
    Write-Host -ForegroundColor Green "Successfully created Kibana data view for '$indexName'."
}
catch {
    Write-Warning "Failed to create Kibana data view. You may need to create it manually in Kibana. Response: $($_.Exception.Response.Content | Out-String)"
    # This is a non-critical failure, so we continue.
}

# --- 5. Fetch, Sanitize, and Prepare Logs ---
Write-Host "Fetching logs from all running containers..."
$containerIds = docker ps -q

if ($null -eq $containerIds) {
    Write-Warning "No running containers found. Exiting."
    exit 0
}

$bulkPayload = [System.Collections.Generic.List[string]]::new()

foreach ($id in $containerIds) {
    $containerName = docker inspect --format '{{.Name}}' $id | ForEach-Object { $_.TrimStart('/') }
    Write-Host "Processing logs for container: $containerName ($id)"

    # Fetch logs. The --timestamps flag adds the timestamp we need.
    $logs = docker logs --timestamps --since $dockerSinceTime $id 2>&1

    foreach ($logLine in $logs) {
        # Docker log format is: "YYYY-MM-DDTHH:MM:SS.ffffffZ The actual log message"
        if ($logLine -match '^(?<timestamp>.*?Z)\s(?<message>.*)') {
            $logTimestamp = $Matches.timestamp
            $logMessage = $Matches.message

            # Sanitize the message
            $sanitizedMessage = $logMessage -replace $piiRegex, $redactionText

            # Create the action and source for the bulk payload
            $action = @{ index = @{ _index = $indexName } } | ConvertTo-Json -Compress
            $source = @{
                "@timestamp"     = $logTimestamp
                "container_name" = $containerName
                "container_id"   = $id
                "message"        = $sanitizedMessage
            } | ConvertTo-Json -Compress -Depth 4

            $bulkPayload.Add($action)
            $bulkPayload.Add($source)
        }
    }
}

# --- 6. Upload Logs to Elasticsearch ---
if ($bulkPayload.Count -eq 0) {
    Write-Warning "No new log entries found to upload."
    exit 0
}

Write-Host "Uploading $($bulkPayload.Count / 2) log entries to Elasticsearch..."

# The Bulk API requires each JSON object to be on a new line.
# We add a final newline to the end of the payload as required.
$finalPayload = ($bulkPayload -join "`n") + "`n"

try {
    $uploadParams = @{
        Uri         = "$elasticUrl/_bulk"
        Method      = 'POST'
        Headers     = $headers
        Body        = $finalPayload
        ContentType = 'application/x-ndjson'
    }
    # Use credential if defined
    if ($credential) { $uploadParams.Credential = $credential }

    Invoke-RestMethod @uploadParams -ErrorAction Stop
    Write-Host -ForegroundColor Green "Successfully uploaded all logs!"
    Write-Host "You can now analyze your data in Kibana under the '$indexName' data view."
}
catch {
    Write-Error "Failed to upload logs to Elasticsearch. Response: $($_.Exception.Response.Content | Out-String)"
    exit 1
}

# # Gather system metrics
# $Username = "elastic"
# $Password = "blarney"

# # Prepare the headers for the HTTP request
# # Using Basic Authentication with the provided username and password

# $credentials = "$($Username):$($Password)"
# $credentialBytes = [System.Text.Encoding]::ASCII.GetBytes($credentials)
# $EncodedCredentials = [System.Convert]::ToBase64String($credentialBytes)
# # above can be scrapped if using a secure method to store credentials

# # Define the headers for the HTTP request
# # This includes the Authorization header for Basic Authentication


# # Added try catch block to handle potential errors in the script
# # CPU usage, memory usage, and disk usage # Ideas for testing more metrics can be added later
# # This section gathers system metrics and prepares them for sending to Elasticsearch
# # Prepare the document to send to Elasticsearch
# # Adjust the structure as needed for your Elasticsearch index


# # Convert this to docker logs?
# $doc = @{
#     timestamp = (Get-Date).ToString("o")
#     machine = $env:COMPUTERNAME
#     cpu_percent = [math]::Round($cpu, 2)
#     memory_used_mb = [math]::Round($usedMem / 1024, 2)
#     disk_used_gb = [math]::Round($disk.Used / 1GB, 2)
#     disk_free_gb = [math]::Round($disk.Free / 1GB, 2)
# }


#     # Find and store the matching lines first. This is also more efficient.
#     $errorLines = $logs | Select-String -Pattern 'ERROR' -CaseSensitive
#     $warningLines = $logs | Select-String -Pattern 'WARN' -CaseSensitive

#     # Display the summary and return the log data.
#     Write-Host "`n--- Analysis Summary ---"
#     Write-Host "Total lines found: $($logs.Count)" -ForegroundColor Green
#     Write-Host "Error lines found: $($errorLines.Count)" -ForegroundColor ($errorLines.Count -gt 0 ? 'Red' : 'Green')
#     Write-Host "Warning lines found: $($warningLines.Count)" -ForegroundColor ($warningLines.Count -gt 0 ? 'Yellow' : 'Green')
    

#     # if loop to generate a log file if the LogToFile switch is specified
#     if ($LogToFile) {
#         $matchedLines = $errorLines, $warningLines
#         if ($matchedLines.Count -gt 0) {
#             $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
#             $logFileName = "$($selectedContainerName)_errors_$timestamp.txt"
#             $logPath = Join-Path -Path $PSScriptRoot -ChildPath $logFileName
        
#             Write-Host "Saving matched lines to: $logPath" -ForegroundColor Cyan
#             $matchedLines | ForEach-Object { $_.Line } | Out-File -FilePath $logPath -Encoding utf8
#         }
#     }
#     Write-Host "----------------------`n"
#     # Return the actual log lines to the pipeline so they can be used by other commands.
#     return $logs
# }
# # Gather system metrics


# # Convert the document to JSON and send it to Elasticsearch
# # Replace 'index-name' and 'document-id' with your actual index and document ID

# write-host $doc | ConvertTo-Json -Depth 5 # Catch a visual of the document structure

# # Test platform connection to Elasticsearch
# Write-Host "Testing general connection to local elastic instance..."
# try {
#     $esrootResponse = Invoke-RestMethod -Uri (Split-Path $esUri -Parent) -Headers $headers -ErrorAction Stop
#     Write-Host "Connection to Elasticsearch instance successful."
#     Write-Host "Elasticsearch version: $($esrootResponse.version.number)"
#     Write-Host "Cluster name: $($esrootResponse.cluster_name)"
# }
# catch {
#     Write-Warning "Failed to connect to Elasticsearch instance: $_"
#     exit 1
# }


# $credentials = Get-Credential "Please enter your credentials for secure processing"
# $credentials | Export-Clixml -Path "$env:USERPROFILE\Desktop\credentials.xml"
# $secureCredentials = Import-Clixml -Path "$env:USERPROFILE\Desktop\credentials.xml"
# # Send the document to Elasticsearch