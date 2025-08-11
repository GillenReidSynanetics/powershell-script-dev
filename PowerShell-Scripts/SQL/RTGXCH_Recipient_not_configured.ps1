<#
.SYNOPSIS
    This script reads a log file to identify recipients not configured for electronic delivery and sends an email report.

.DESCRIPTION
    The script reads a log file located at "C:\Synanetics\SQL\RTGXCH_Recipient_not_configured.log" to find recipients who are not configured for electronic delivery.
    It parses the log file, extracts the recipient IDs, and sends an email report with the list of unconfigured recipients.

.PARAMETERS
    None

.EXAMPLE
    .\RTGXCH_Recipient_not_configured.ps1
    This example runs the script and sends an email report with the list of unconfigured recipients.

.NOTES
    The script uses the Send-MailMessage cmdlet to send the email report.
    Ensure that the SMTP server 'mailrelay.uhdb.nhs.uk' is accessible and configured correctly.

#>

$SQLResult = "C:\Synanetics\SQL\RTGXCH_Recipient_not_configured.log"




try {
    Clear-Host
    $Recipients = @()
    $reader = New-Object System.IO.StreamReader($SQLResult)
    if ($reader -ne $null) {
        $Searching = $False
        while (!$reader.EndOfStream) {
            $line = $reader.ReadLine()
            
            $result = $line.Split("`t")

            if ($Searching -eq $True -and $result[0] -ne "") {
                $Recipient = $result[8].Split(",")[0].Split(")")[1].Replace(" as recipient ","").Replace(" is not configured for electronic delivery","")

                if ($Recipients -notcontains $Recipient) {
                    $Recipients+= $Recipient
                }
            }
            #$result

            if ($result[0] -eq "ID") {
                $Searching = $True
            } elseif  ($result[0] -eq "") {
                $Searching = $False 
            }
        }
    }
    $reader.Close()
    $reader.Dispose()


    
    if ($Recipients.Count -ge 0) {
        $to_list = @("ssd@synanetics.atlassian.net","mark.bain@synanetics.com")
        $title = "SSD-7890 - Missing MESH Recipient Report (Testing)"
        $table = $Recipients  | Select @{label='Recipient ID';expression={$_}} | ConvertTo-HTML -Fragment -Property 'Recipient ID'
        $html = "<h2>$title</h2>" 

        $html += "<p>These are the MESH IDs that have <b>not</b> been configured for messages sent in the last 7 days:</p>"
        $html += $table
        #foreach ($to in $to_list) {
            Send-MailMessage -From 'ensemble.tie@uhdb.nhs.uk' -To $to_list -Subject "$title" -Body "$html" -BodyAsHtml -SmtpServer 'mailrelay.uhdb.nhs.uk'
       # }
    }
} Catch {
    "Whoops"
}


