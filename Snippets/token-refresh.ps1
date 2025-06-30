# Idea is to setup a module that automatically refreshes the token when it expires
# initial idea is to deploy to task scheduler and run every X minutes depending on the token expiration time
# 


# Jira instance details
$Username = ""
$apiToken = ""
$credentialBytes = [System.Text.Encoding]::ASCII.GetBytes("$Username':$apiToken")
$EncodedCredentials = [System.Convert]::ToBase64String($credentialBytes)
$JiraUrl = "https://your-jira-instance.atlassian"

# Define headers
$Headers = @{
    "Authorization" = "Basic $encodedCredentials"
    "Content-Type"  = "application/json"
}

# Fetch the issue details
try {
    $IssueResponse = Invoke-RestMethod -Uri $IssueUrl -Method Get -Headers $Headers

    # Extract status from the response
    $IssueStatus = $IssueResponse.fields.status.name

    Write-Output "Issue: $IssueKey"
    Write-Output "Status: $IssueStatus"
} catch {
    Write-Output "Error retrieving issue details: $_"
}