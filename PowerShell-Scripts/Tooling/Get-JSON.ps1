<#
.SYNOPSIS
Retrieves JSON data from a user-provided URL and outputs it in formatted JSON.

.DESCRIPTION
Prompts the user to enter a URL pointing to a JSON resource. Attempts to retrieve and parse the JSON data from the specified URL. If successful, outputs the formatted JSON. Handles errors related to missing input or failed retrieval/parsing.

.PARAMETER url
The URL of the JSON resource to retrieve. Entered interactively by the user.

.EXAMPLE
PS> .\get-script.ps1
Please enter the JSON you wish to retrieve: https://api.example.com/data

.NOTES
- Requires internet access to retrieve remote JSON resources.
- Outputs errors and exits with code 1 on failure.
#>
$url = Read-Host "Please enter the JSON you wish to retrieve"
if (-not $url) {
    Write-Error "No URL provided. Exiting."
    exit 1
}
try {
    $responseJson = Invoke-RestMethod -Uri $url -ErrorAction Stop
    $jsonOutput = $responseJson | ConvertTo-Json -Depth 10
    write-output $jsonOutput
}
catch {
    Write-Error "Failed to retrieve or parse JSON from the provided URL. $_"
    exit 1
}