<#
.SYNOPSIS
    Retrieves the A record (IPv4 address) for a given URL.

.DESCRIPTION
    This script defines a function `Get-ARecord` that takes a URL as input and attempts to resolve its A record using the `Resolve-DnsName` cmdlet. 
    If successful, it returns the IP address associated with the URL. If it fails, it catches the error and outputs a failure message.

.PARAMETER url
    The URL for which to retrieve the A record.

.EXAMPLE
    Get-ARecord -url "example.com"
    This command retrieves the A record for "example.com".

.NOTES
    The main script initializes an array of URLs and iterates through each URL to retrieve its A record using the `Get-ARecord` function.
    The results are collected and written to a file named "dns_results.txt".

.INPUTS
    [string] The URL for which to retrieve the A record.

.OUTPUTS
    [string] The IP address of the given URL, if resolved successfully.
#>
# Function to get A record for a URL
function Get-ARecord {
    param(
        [string]$url
    )
    try {
        $result = Resolve-DnsName -Name $url -Type A -ErrorAction Stop
        $result.IPAddress
    } catch {
        Write-Host "Failed to retrieve A record for $url : $_"
        return $null
    }
}

# Main script
$urls = @(
    "example.com",
    "google.com",
    "openai.com"
    # Add more URLs as needed
)

$results = @()

foreach ($url in $urls) {
    $ipAddress = Get-ARecord $url
    if ($ipAddress) {
        $results += "A record for $url : $ipAddress"
    }
}

$results | Out-File -FilePath "dns_results.txt"
Write-Host "Results written to dns_results.txt"
