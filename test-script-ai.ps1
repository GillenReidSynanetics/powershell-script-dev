$apiKey = "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"
$aiEndpoint = "https://api.openai.com/v1/chat/completions"

$model = "gpt-3.5-turbo"

$userMessage = Read-Host "Ask something to the AI"


# Create request body
$body = @{
    model = $model
    messages = @(
        @{ role = "system"; content = "You are an eve online knowledge base master" }
        @{ role = "user"; content = $userMessage }
    )
} | ConvertTo-Json -Depth 3


$headers = @{
    "Authorization" = "bearer $apiKey"
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod -Uri $aiEndpoint -Method Post -Headers $headers -Body $body
Write-Host = $response


Invoke-WebRequest -Uri https://eve-static-data-export.s3-eu-west-1.amazonaws.com/tranquility/sde.zip