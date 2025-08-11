
# This script sets up a simple HTTP listener to receive webhooks.
# It listens for incoming requests and processes them.

$listenerUrl = "http://localhost:8080/"  # Change the port if needed
$logfilePath = ".\webhook_log.txt"  # Path to log file

$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add($listenerUrl)


write-host "Starting HTTP listener on $listenerUrl"


try {
    $listener.start()
    write-host "Listening for incoming requests on $listenerUrl"
    write-host "logs will be posted to $logfilePath"
    write-host "Press Ctrl+C to stop the listener or use the command: Invoke-RestMethod -Uri $listenerUrl -Method POST -Body 'shutdown' to stop it gracefully."
    $keeprunning = $true

    while ($keeprunning -and $listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        $reader = New-Object System.IO.StreamReader($request.InputStream, [system.text.encoding]::UTF8)
        $body = $reader.ReadToEnd()

        $requestDetails = [PSCustomObject]@{
            Timestamp   = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.fff")
            Method      = $request.HttpMethod
            Url         = $request.Url.ToString()
            LocalPath   = $request.Url.LocalPath
            QueryString = $request.Url.Query
            Headers     = ($request.Headers | ConvertTo-Json -Compress) # Convert headers to JSON string
            Body        = $body
            ClientIP    = $request.RemoteEndPoint.Address.ToString()
        }

        if ($body -eq "shutdown" -and $request.HttpMethod -eq "POST" -and $request.Url.LocalPath -eq "/") { 
            write-host "-- Received shutdown command, stopping listener --"
            $keeprunning = $false
            $response.StatusCode = 200
            $response.StatusDescription = "Shutdown command received"
        }
        else {
            Write-Host "---"
            Write-Host "Received Request [$(($requestDetails.Timestamp))]:"
            Write-Host "  Method: $($requestDetails.Method)"
            Write-Host "  URL: $($requestDetails.Url)"
            Write-Host "  Client IP: $($requestDetails.ClientIP)"
            Write-Host "  Headers: $($requestDetails.Headers | ConvertFrom-Json | Format-List | Out-String)" # Pretty print headers
            Write-Host "  Body: '$($requestDetails.Body)'"
        }
        # --- Append to Log File ---
        try {
            $requestDetails | ConvertTo-Json -Depth 10 | Add-Content -Path $logFilePath
            Write-Host "  Request logged to '$logFilePath'"
        }
        catch {
            Write-Error "Failed to write to log file: $($_.Exception.Message)"
        }

        # --- Prepare and Send Regular Response ---
        $response.StatusCode = 200
        $response.StatusDescription = "OK"
        $responseString = "Request processed successfully by tester."
    }

    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
    $response.ContentLength64 = $buffer.Length
    $response.OutputStream.Write($buffer, 0, $buffer.Length)
    $response.OutputStream.Flush()
    $response.OutputStream.Close()

    Write-Host "  Response sent: '$responseString'"
}

catch {
    Write-Error "An error occurred in the listener: $($_.Exception.Message)"
}
finally {
    # --- Clean Up ---
    if ($listener.IsListening) {
        $listener.Stop()
        Write-Host "Listener stopped."
    }
    $listener.Close()
    Write-Host "Listener closed."
}

Write-Host "Webhook tester script finished."
# End of script
# To run this script, save it as webhook.ps1 and execute it in PowerShell.