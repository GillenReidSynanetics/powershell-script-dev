$RunDate = (Get-Date -f yyyyMMdd)

# Check if AD module is loaded
If (!(Get-Module ActiveDirectory)) {
    Import-Module ActiveDirectory
}

Write-Host "Retrieving Computers in Active Directory..."

$ADComputer = Get-ADComputer -Filter {Enabled -eq $true -and OperatingSystem -Like "*Server*"} -Properties *
$Total = $ADComputer.Count
Write-Host "Total Computer = $Total"
Write-Host "ID - ComputerName IPAddress Days hh:mm:ss"

$Count = 1
$Report = @()

Foreach ($Computer in $ADComputer) {
    If (Test-Connection $Computer.Name -TimeToLive 5 -Count 1) {
        $os = Get-WmiObject Win32_OperatingSystem -ComputerName $Computer.Name
        $LastReboot = [DateTime]$os.ConvertToDateTime($os.LastBootUpTime)
        $TGap = New-TimeSpan $LastReboot
        $TimeGap = "{0}:{1}:{2}" -f $TGap.Hours, $TGap.Minutes, $TGap.Seconds

        Write-Host -ForegroundColor Green "$Count - $($Computer.Name) $($Computer.IPv4Address) $($TGap.Days) $TimeGap"

        $Report += [PSCustomObject][ordered]@{
            Computer     = $Computer.Name
            IPAddress    = $Computer.IPv4Address
            LastReboot   = $LastReboot
            NumberOfDays = $TGap.Days
            "hh:mm:ss"   = $TimeGap
            RunDate      = $RunDate
        }
    } else {
        Write-Host -ForegroundColor Red "$Count - $($Computer.Name)"

        $Report += [PSCustomObject][ordered]@{
            Computer     = $Computer.Name
            IPAddress    = "Unavailable"
            LastReboot   = "Offline"
            NumberOfDays = "N/A"
            "hh:mm:ss"   = "N/A"
            RunDate      = $RunDate
        }
    }

    $Count++
}

# Optional: Export the report
# $Report | Export-Csv -Path "ServerUptimeReport_$RunDate.csv" -NoTypeInformation
