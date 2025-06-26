<#
.SYNOPSIS
   Clears the DNS client cache and measures the time taken to complete the operation.

.DESCRIPTION
   This script clears the DNS client cache on the local machine using the Clear-DnsClientCache cmdlet.
   It also measures the elapsed time for the operation and outputs the result.

.EXAMPLE
   .\dnscache-clear.ps1
   This command runs the script to clear the DNS client cache and displays the elapsed time.

.NOTES
   Author: GillenReidSynanetics
   FilePath: /GillenReidSynanetics/syn-support-operational-scripts/Beta/dnscache-clear.ps1

#>
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