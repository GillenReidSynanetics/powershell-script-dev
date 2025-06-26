<#
.SYNOPSIS
    Processes and analyzes log data from the EXCHANGE_TotalInbound.log file.

.DESCRIPTION
    This script reads and processes log data from the specified log file to calculate various metrics related to message processing.
    It calculates totals for inbound and outbound messages, discrepancies, conversion errors, and MDM message details.

.PARAMETERS
    None

.NOTES
    Author: Mark Bain   
    Version: 1.0

.EXAMPLE
    .\EXCHANGE_TotalInbound_Process.ps1
    This will execute the script and output the calculated metrics to the console.

#>
try {
    Clear-Host
    $Log = "C:\Synanetics\SQL\EXCHANGE_TotalInbound.log"

    if ($null -ne $reader) {
        $reader.Close()
        $reader.Dispose()
    }
    $ProcessTotals = $False
    $ProcessMDM = $False
    $meditech_total_inbound = 0
    $cito_total_outbound = 0
    $cito_total_inbound = 0
    $empty = 0
    $populated = 0
    $MDMCount =0
    $meditech_total_error = 0
    $reader = New-Object System.IO.StreamReader($Log)
    if ($reader -ne $null) {
        while (!$reader.EndOfStream) {
            $logInput = $reader.ReadLine().Split("`t")

            if ($logInput[0] -eq "SourceConfigName") {
                "Start Totals"
                $ProcessTotals = $True
            } elseif ($logInput[0] -eq "RawContent") {
                "Start MDM"
                $ProcessMDM = $True
            } elseif ($logInput[0] -eq "") {
     
                 $ProcessTotals = $False
        
            } elseif ($ProcessTotals) {
                $source = $logInput[0]
                $target =   $logInput[1]
                $messages =  $logInput[2]
               

                if (($source -eq "MEDITECH.INBOUND.FILE.ED" -or $source -eq "MEDITECH.INBOUND.FILE.INPATIENT") -and ($target -eq "Meditech.Document.Inbound.DocumentConverter")) {
                    $meditech_total_inbound += $messages
                } elseif ($source -eq "CITO.INTERNAL.SQL" -and $target -eq "CITO.INBOUND.DOCUMENTPROCESSOR" ) {
                     $cito_total_inbound += $messages
                } elseif ($target -eq "CITO.OUTBOUND.TCP.HL7.MDM") {
                    $cito_total_outbound += $messages
                } elseif ($source -eq "MEDITECH.DOCUMENT.INBOUND.DOCUMENTCONVERTER" -and $target -eq "ENS.ALERT" ) {
                    $meditech_total_error = $messages
                } else {
                    $source + " -> " + $target + " = " + $messages
                }
            }  elseif ($ProcessMDM) {
                 if (($logInput[0] -as [int]) -is [int]) {

                
                $session = $logInput[0]
                $sessions += $session
                $line = $logInput[1]
                $i++
               
            } else {
                $line = $logInput[0]
            }
           

            if ($null -eq $line) {Continue}

            $hl7 = $line.Split("|")


            if (($hl7[0] -eq "MSH" -and $Document -ne "" ) -or ($hl7[0] -eq "" -and $Document -ne "" )) {
               # if (!$PDFProcessed) {
                  #  $Text = $DateTime+","+$Session + "," + $Document + "," + $PDFProcessed
                   
                 #   $Text
                    #Add-Content -Path $Output $Text
               # }
                $Document = ""
                $PDFProcessed = $False
                
            }
            if ($hl7[0] -eq "MSH") {
                $DateTime = $hl7[6]
                $MDMCount++
               
            }

            if  ($hl7[0] -eq "TXA") {
                $Document = $hl7[12]
                 
               
            }
            if  ($hl7[0] -eq "OBX" ) {
                $Fields = $hl7[5].Split("^")
                if ($Fields[2] -eq "PDF" ) {
                    if ($Fields[4] -eq "") {
                        $empty++
                        $PDFProcessed = $False
                     } else {
                        $populated++
                        $PDFProcessed = $True

                     }
                }
            
            }
            }
        }
    }
    "Messages from Meditech:`t`t`t$meditech_total_inbound"
    "Messages from Cito Database:`t$cito_total_inbound"

    $discrepancy = $meditech_total_inbound - $cito_total_outbound
    "Discrepancy:`t`t`t`t`t$discrepancy"
    "Conversion Errors:`t`t`t`t$meditech_total_error"

    $undefinederrors = $discrepancy - $meditech_total_error
    "Undefined Errors::`t`t`t`t$undefinederrors"

    "____________________________________"



     $total = $populated + $empty 
     $totalMessages = $populated + $empty 
     "Total MDM Messages:`t`t`t`t$MDMCount"
     $MDMdiscrepancy = $cito_total_outbound - $MDMCount
     "Discrepancy :`t`t`t`t`t$MDMdiscrepancy"
     "MDM Messages with Empty OBX:`t$empty" 
     "____________________________________"



     

} catch {
    "-----------------------ERROR---------------------------"
    $_
    "-------------------------------------------------------"
} Finally {
    if ($reader -ne $null) {
        $reader.Close()
        $reader.Dispose()
    }
}