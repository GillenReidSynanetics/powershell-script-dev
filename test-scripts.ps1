$response = Invoke-RestMethod "https://api.openweathermap.org/data/2.5/weather?q=Glasgow&appid=YOUR_API_KEY&units=metric"
Write-Host = $response

Invoke-RestMethod -Uri "https://icanhazdadjoke.com/" -Headers @{Accept = "application/json" } | Select-Object -ExpandProperty joke
