<#
.SYNOPSIS
    Gathers and displays basic network information.

.DESCRIPTION
    This script collects and displays various network configuration details including network adapters, DHCP servers, DNS servers, and default gateway information. It can be modified to add an output file if needed.

.PARAMETER None
    This script does not take any parameters.

.OUTPUTS
    Displays network configuration details in a formatted table.

.EXAMPLE
    PS C:\> .\network-probe.ps1
    This will execute the script and display the network information on the console.

#>
#Script gathers some basic network information - can be modified to add an output file.


$NetworkConfig = Get-NetIPConfiguration | Where-Object { $_.IPv4Address -ne $null }
$Adapters = Get-NetAdapter | Select-Object Name, InterfaceDescription, Status, MacAddress, DHCPEnabled

try {
    $DhcpServer = Get-DhcpServerv4Scope | Select-Object ScopeId, Name, StartRange, EndRange
} catch {
    $DhcpServer = @("DHCP server information not available.")
}

$DnsServers = Get-DnsClientServerAddress | Select-Object InterfaceAlias, ServerAddresses
$DefaultGateway = Get-NetRoute -DestinationPrefix "0.0.0.0/0" | Select-Object NextHop, InterfaceAlias

Write-Host "`nNetwork Configuration:"
$NetworkConfig | Format-Table IPv4Address, InterfaceAlias, DNSSuffix -AutoSize
Write-Host "`nNetwork Adapters:"
$Adapters | Format-Table Name, Status, MacAddress, DHCPEnabled -AutoSize
Write-Host "`nDHCP Servers:"
if ($DhcpServer -is [array]) {
    $DhcpServer | Format-Table ScopeId, Name, StartRange, EndRange -AutoSize
} else {
    Write-Host $DhcpServer
}
Write-Host "`nDNS Servers:"
$DnsServers | Format-Table InterfaceAlias, @{Name="DNS Servers"; Expression={($_.ServerAddresses -join ", ")}} -AutoSize

Write-Host "`nDefault Gateway:"
$DefaultGateway | Format-Table NextHop, InterfaceAlias -AutoSize

Write-Host "`nNetwork Probe Complete"
Read-Host "Press Enter to Close"