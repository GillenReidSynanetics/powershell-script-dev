# configuration

$hostname = "localhost"
$projectKey = "ssl-notification"
$jiraUser = "jira"
$jiraApiToken = "your_api_token_here"
$jiraUri = "https://your_jira_instance.atlassian.net"
$threshold = 5


$base64Auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("${jiraUser}:${jiraApiToken}"))

function Get-SSLCertificateExpiry {
    param ([string]$hostname, [int]$port = 443)

    try {
        $tcpClient = New-Object Net.Sockets.TcpClient($hostname, $port)
        $sslStream = New-Object System.Net.Security.SslStream($tcpClient.GetStream(), $false, ({ $true }))
        $sslStream.AuthenticateAsClient($hostname)

        $cert = $sslStream.RemoteCertificate
        $cert2 = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2 $cert

        $expiry = $cert2.NotAfter
        $tcpClient.Close()

        return $expiry
    } catch {
        Write-Warning "Could not retrieve certificate for ${hostname}:${port}"
        return $null
    }
}

# === Function: Create Jira Ticket ===
function New-JiraTicket {
    param (
        [string]$Summary,
        [string]$Description,
        [string]$ProjectKey,
        [string]$IssueType = "Task"
    )

    $uri = "$jiraUri/rest/api/2/issue"
    $headers = @{
        Authorization = "Basic $base64Auth"
        "Content-Type" = "application/json"
    }

    $body = @{
        fields = @{
            project     = @{ key = $ProjectKey }
            summary     = $Summary
            description = $Description
            issuetype   = @{ name = $IssueType }
        }
    } | ConvertTo-Json -Depth 5

    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body
        Write-Host "✅ Jira ticket created: $($response.key)"
    } catch {
        Write-Error "❌ Failed to create Jira ticket: $_"
    }
}

# === Main Logic ===
$expiry = Get-SSLCertificateExpiry -Hostname $hostname

if ($null -ne $expiry) {
    $daysLeft = ($expiry - (Get-Date)).Days
    Write-Host "$hostname certificate expires in $daysLeft days"

    if ($daysLeft -lt $threshold) {
        $summary = "SSL Certificate Expiry: $hostname in $daysLeft days"
        $description = "Heads up — the SSL certificate for `$hostname` is expiring soon.`nExpiry: $expiry`nRemaining: $daysLeft days"

        Create-JiraTicket -Summary $summary -Description $description -ProjectKey $projectKey
    } else {
        Write-Host "✅ Certificate is fine. $daysLeft days remaining."
    }
} else {
    Write-Error "❌ Could not fetch expiry information for $hostname"
}