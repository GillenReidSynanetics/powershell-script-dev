
try {       
         $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
         Clear-DnsClientCache
         [int]$elapsed = $stopwatch.Elapsed.TotalSeconds
            Write-Host "Elapsed time: $elapsed seconds" -ForegroundColor Green
            Write-Host "DNS cache cleared successfully" -ForegroundColor Green
            exit 0
} catch {
            Write-Host "Failed to clear DNS cache" -ForegroundColor Red
            exit 1

try  {
         Clear-RecycleBin -Force -Confirm:$false
         if ($LASTEXITCODE -ne "0") {
            Write-Host "Failed to clear Recycle Bin" -ForegroundColor Red
            exit 1
         } else {
            Write-Host "Recycle Bin cleared successfully" -ForegroundColor Green
            exit 0
         }
} catch {      
         Write-Host "Failed to clear Recycle Bin" -ForegroundColor Red
         exit 1
}
}