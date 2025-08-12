<#
.SYNOPSIS
    Scans the local IPv4 subnet for active hosts and displays their IP addresses and hostnames.

.DESCRIPTION
    The Get-LocalNetworkScan function identifies the local network based on the active network adapter with an IPv4 default gateway.
    It then scans all possible host addresses in the subnet (typically .1 to .254) by sending ICMP echo requests (pings) in parallel.
    For each responsive host, it attempts to resolve the hostname via DNS.
    The results are returned as a formatted table, showing the IP address, hostname, and online status of each discovered host.

.NOTES
    - Requires PowerShell 7.0 or higher for the -Parallel parameter in ForEach-Object.
    - The scan is limited to /24 subnets (254 hosts).
    - Hostname resolution may fail for some devices, in which case "N/A" is shown.
    - ThrottleLimit controls the number of concurrent pings.

.EXAMPLE
    PS C:\> Get-LocalNetworkScan

    Scans the local network and displays a table of online hosts with their IP addresses and hostnames.
#>
function Get-LocalNetworkScan {
    [CmdletBinding()]
    param (
        )
}

$ipConfig = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -ne $null -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1
if (-not $ipConfig) {
    Write-Host "No active network adapters with IPv4 default gateway found." -ForegroundColor Red
    return
}

    $ipAddress = $ipConfig.IPv4Address.IPAddress
    $prefixLength = $ipConfig.IPv4Address.PrefixLength
    $networkId = ($ipAddress.Split('.')[0..2] -join '.') + ".0"
    
    Write-Host "Local network identified: $networkId/$prefixLength" -ForegroundColor Yellow
    Write-Host "Scanning 254 hosts... (This may take a minute)" -ForegroundColor Cyan

    # 2. Create an array of all IPs in the subnet to scan (from 1 to 254)
    $ipRange = 1..254 | ForEach-Object { "$($networkId.TrimEnd('0'))$_" }

    # 3. Ping all IPs in parallel to find active hosts (requires PowerShell 7+)
    $scanResults = $ipRange | ForEach-Object -Parallel {
        $ip = $_
        # Test-Connection with -Quiet is a fast way to check if a host is online
        if (Test-Connection -ComputerName $ip -Count 1 -TimeoutSeconds 1 -Quiet) {
            # 4. If the host is online, try to get its hostname
            try {
                $dnsResult = [System.Net.Dns]::GetHostEntry($ip)
                $hostname = $dnsResult.HostName
            }
            catch {
                $hostname = "N/A"
            }

            # 5. Output a result object for this host
            [PSCustomObject]@{
                IPAddress = $ip
                Hostname  = $hostname
                Status    = "Online"
            }
        }
    } -ThrottleLimit 50 # Run up to 50 pings at the same time

    # Return the results, sorted by IP address
return $scanResults | Sort-Object { [version]$_.IPAddress } | Format-Table -AutoSize