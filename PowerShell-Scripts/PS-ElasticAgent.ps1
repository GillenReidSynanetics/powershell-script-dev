
# Self-contained PowerShell script to gather system metrics and send them to Elasticsearch
# This script is designed to run on a local machine and send metrics to a specified Elasticsearch index
# Further options down the line could include more metrics, such as network usage, process counts, etc.
# Ensure the script is run with appropriate permissions to access system metrics and Elasticsearch
# Potentially using this to deploy to a azure function app or similar service for production usage?
# Scenario is where clients are obstucting access/refusing deployment of agents


# Configuration for Elasticsearch connection
$Username = "elastic"
$Password = "blarney"
$esUri = "https://localhost:9200/local-machine-test/_doc/f6276f8d-7eba-4991-8945-7910c31e77bd" # formatting ideas for the URI to identify the machine and document?

# Prepare the headers for the HTTP request
# Using Basic Authentication with the provided username and password

$credentials = "$($Username):$($Password)"
$credentialBytes = [System.Text.Encoding]::ASCII.GetBytes($credentials)
$EncodedCredentials = [System.Convert]::ToBase64String($credentialBytes)

# Define the headers for the HTTP request
# This includes the Authorization header for Basic Authentication
$headers = @{
    Authorization = "Basic $($EncodedCredentials)"
    "Content-Type" = "application/json"
} # Define the content type as JSON for the request

# Added try catch block to handle potential errors in the script
# CPU usage, memory usage, and disk usage # Ideas for testing more metrics can be added later
# This section gathers system metrics and prepares them for sending to Elasticsearch
Write-Host "Gathering system metrics..."
try {
    $cpu = (Get-Counter '\Processor(_Total)\% Processor Time').CounterSamples.CookedValue
    $mem = get-ciminstance win32_operatingsystem | Select-Object -ExpandProperty TotalVisibleMemorySize
    $usedMem = $mem.TotalVisibleMemorySize - $mem.FreePhysicalMemory
    $disk = Get-PSDrive C # further ideas for metrics? What could be useful?
}
catch {
    Write-Warning "Failed to retrieve system metrics: $_"
}

# Prepare the document to send to Elasticsearch
# Adjust the structure as needed for your Elasticsearch index

$doc = @{
    timestamp = (Get-Date).ToString("o")
    machine = $env:COMPUTERNAME
    cpu_percent = [math]::Round($cpu, 2)
    memory_used_mb = [math]::Round($usedMem / 1024, 2)
    disk_used_gb = [math]::Round($disk.Used / 1GB, 2)
    disk_free_gb = [math]::Round($disk.Free / 1GB, 2)
}

# Convert the document to JSON and send it to Elasticsearch
# Replace 'index-name' and 'document-id' with your actual index and document ID

write-host $doc | ConvertTo-Json -Depth 5 # Catch a visual of the document structure

# Test platform connection to Elasticsearch
Write-Host "Testing general connection to local elastic instance..."
try {
    $esrootResponse = Invoke-RestMethod -Uri (Split-Path $esUri -Parent) -Headers $headers -ErrorAction Stop
    Write-Host "Connection to Elasticsearch instance successful."
    Write-Host "Elasticsearch version: $($esrootResponse.version.number)"
    Write-Host "Cluster name: $($esrootResponse.cluster_name)"
}
catch {
    Write-Warning "Failed to connect to Elasticsearch instance: $_"
    exit 1
}


