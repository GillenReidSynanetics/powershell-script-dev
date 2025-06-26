$esiURL = "https://esi.evetech.net/latest/status/"
$esiUrl = $esiURL + "?datasource=tranquility"
 try {
    $response = Invoke-RestMethod -Uri $esiUrl -Method Get

    # Output key information
    Write-Host "📡 EVE Online Server Status" -ForegroundColor Cyan
    Write-Host "Players Online : $($response.players)"
    Write-Host "Server Version : $($response.server_version)"
    Write-Host "Start Time     : $($response.start_time)"
}
catch {
    Write-Warning "Failed to fetch server status. $_"
}