# Helper function to correctly calculate the IP range from a subnet prefix
function Get-SubnetIPRange {
    param(
        [string]$IPAddress,
        [int]$PrefixLength
    )
    $ip = [System.Net.IPAddress]::Parse($IPAddress).GetAddressBytes()
    $mask = [System.Net.IPAddress]::new([byte[]]([byte[]](1..$PrefixLength | ForEach-Object { 1 }) + [byte[]](1.. (32 - $PrefixLength) | ForEach-Object { 0 }) | ForEach-Object -begin { $m = '' } -process { $m += $_ } -end { ($m -split '(\d{8})' | Where-Object { $_ }) | ForEach-Object { [Convert]::ToByte($_, 2) } })).GetAddressBytes()

    $networkBytes = for ($i = 0; $i -lt 4; $i++) { $ip[$i] -band $mask[$i] }
    $broadcastBytes = for ($i = 0; $i -lt 4; $i++) { $networkBytes[$i] -bor ((-bnot $mask[$i]) -band 0xFF) }

    $firstHost = [System.Net.IPAddress]::new([byte[]]($networkBytes[0..2] + ($networkBytes[3] + 1)))
    $lastHost = [System.Net.IPAddress]::new([byte[]]($broadcastBytes[0..2] + ($broadcastBytes[3] - 1)))

    # Generate all IPs in the range, ensuring we don't create an invalid range on very small subnets
    if ($firstHost.Address -le $lastHost.Address) {
        $startRange = $firstHost.ToString().Split('.')[-1]
        $endRange = $lastHost.ToString().Split('.')[-1]
        $base = "$($firstHost.ToString().Split('.')[0..2] -join '.')"
        return @($startRange..$endRange | ForEach-Object { "$base.$_" })
    } else {
        return @() # Return an empty array for subnets too small to have a scannable range
    }
}


# Step 1: Get the local IP address and subnet mask from the primary network adapter
$ipConfig = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway } | Select-Object -First 1
if (-not $ipConfig) {
    Write-Host "Could not find a valid network adapter with a default gateway."
    exit
}
$ipAddress = $ipConfig.IPv4Address.IPAddress
$prefixLength = $ipConfig.IPv4Address.PrefixLength
Write-Host "Local IP Address: $ipAddress"
Write-Host "Subnet Prefix Length: $prefixLength"


# Step 2: Generate the IP address list using the correct subnet
$ipAddressesToScan = Get-SubnetIPRange -IPAddress $ipAddress -PrefixLength $prefixLength
Write-Host "Generated $($ipAddressesToScan.Count) IP addresses to scan for the /$prefixLength subnet."


# Step 3: Start a separate background job for each IP address with a progress bar
Write-Host "Starting parallel scan... This may take some time depending on network size."
$jobs = @()
$totalIPs = $ipAddressesToScan.Count
$i = 0

foreach ($ip in $ipAddressesToScan) {
    $i++
    Write-Progress -Activity "Dispatching Network Scan Jobs" -Status "Starting job for IP: $ip" -PercentComplete (($i / $totalIPs) * 100)

    $jobs += Start-Job -ScriptBlock {
        param($ipToTest)
        $isOnline = Test-Connection -ComputerName $ipToTest -Quiet -Count 1 -ErrorAction SilentlyContinue
        
        # Return a custom object with the IP and status
        [PSCustomObject]@{
            IP     = $ipToTest
            Online = $isOnline
        }
    } -ArgumentList $ip
}
Write-Progress -Activity "Dispatching Network Scan Jobs" -Completed


# Step 4 & 5: Wait for, receive, and clean up jobs ONLY if they were created
if ($jobs.Count -gt 0) {
    Write-Host "Waiting for $($jobs.Count) jobs to complete..."
    Wait-Job -Job $jobs | Out-Null

    Write-Host "Scan complete."
    Write-Host "--------------------"

    $onlineHosts = Receive-Job -Job $jobs -Keep | Where-Object { $_.Online -eq $true }

    # This command is now safely inside the 'if' block and will not cause an error
    Remove-Job -Job $jobs | Out-Null

    if ($onlineHosts) {
        Write-Host "The following hosts are online:"
        # Sort the IPs correctly for readability
        $onlineHosts | Select-Object -ExpandProperty IP | Sort-Object { [version]$_ }
    } else {
        Write-Host "No other hosts were found online in the subnet."
    }
}
else {
    # This message now appears if there was nothing to scan
    Write-Host "No IP addresses were available to scan in this subnet."
}