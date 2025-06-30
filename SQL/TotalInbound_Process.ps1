<#
.SYNOPSIS
    Processes inbound log files and generates a summary report.

.DESCRIPTION
    This script reads and processes multiple inbound log files to extract and summarize various metrics related to message processing.
    It identifies and counts different types of messages, errors, and discrepancies, and generates a summary report for each log file.

.PARAMETER Logs
    An array of file paths to the log files that need to be processed.

.PARAMETER Temp
    The directory path where temporary scripts or files are stored.

.NOTES
    Author: Mark
    FilePath: /GillenReidSynanetics/syn-support-operational-scripts/Azure/Intune/Mark/TotalInbound_Process.ps1

.EXAMPLE
    .\TotalInbound_Process.ps1
    This will execute the script and process the log files specified in the $Logs array.

#>
try {
    Clear-Host

    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $Logs = @(
        "$scriptDirectory\RTGXCH_TotalInbound_today.log"
        "$scriptDirectory\EXCHANGE_TotalInbound_today.log"
    )

    $Temp = "$scriptDirectory\Temp"

    ForEach ($Log in $Logs) {


        

        if ($null -ne $reader) {
            $reader.Close()
            $reader.Dispose()
        }
        $ProcessTotals = $False
        $ProcessMDM = $False
        $ProcessIdentifiers = $False
        $ProcessPDF = $False
        $ProcessErrorLog = $False
   
        $medisec_total_inbound = 0
        $dictate_total_inbound = 0
        $infoflex_total_inbound = 0
        $cito_total_outbound = 0
        $cito_total_inbound = 0

        $meditech_total_inbound = 0 
        $meditech_total_pdf = 0
        $meditech_total_error = 0

        $empty = 0
        $populated = 0
        $MDMCount =0
        
        $dictate_total_errors = 0 
        $infoflex_total_errors = 0
        $medisec_total_errors = 0
        $Silhouette_total_inbound = 0
        $Silhouette_total_errors = 0
        $Vitaldata_total_inbound = 0
        $Vitaldata_total_errors = 0
        $total_inbound_messages = 0

        $messageids = @()
        $errorSessions = @()
        $Sessions_Messageids = @{}
        $Sessions_PDF = @{}

        $linecount = 0


        $reader = New-Object System.IO.StreamReader($Log)
        if ($null -ne $reader) {
            while (!$reader.EndOfStream) {
                $linecount++
                #if(  !$ProcessMDM) {
               #     $reader.ReadLine()
               # }
                $logInput = $reader.ReadLine().Split("`t")
                
                if ($logInput[0] -eq "SourceConfigName") {
                    $ProcessTotals = $True
                } elseif ($logInput[0] -eq "RawContent") {
                    $ProcessMDM = $True
                } elseif ($logInput[0] -eq "Identifier" -and $logInput[1] -eq "SessionId") {
                    "Found Identifier at line $linecount"
                    $ProcessIdentifiers = $True
                } elseif ($logInput[0] -eq "PDFFileName" -and $logInput[1] -eq "SessionId") {
                    "Found Identifier at line $linecount"
                    $ProcessPDF = $True
                } elseif ($logInput[0] -eq "SessionId" -and $logInput[1] -eq "SourceConfigName" -and $logInput[2] -eq "AlertText") {
                    #SessionId	SourceConfigName	AlertText
                    "Found Error Log at line $linecount"
                    $ProcessErrorLog = $True

                } elseif ($logInput[0] -like "* Rows(s) Affected") {
                    
                     if ($ProcessPDF) {
                        "Stopping Process PDF at line $linecount"
                        $ProcessPDF = $False
                        
                     }
                     if ($ProcessIdentifiers) {
                        "Stopping Process Identifiers at line $linecount"
                        $ProcessIdentifiers = $False
                        
                     }
                     if ($ProcessTotals) {
                        "Stopping Process Totals at line $linecount"
                        $ProcessTotals = $False
                     }
                     if ($ProcessMDM ) {
                        "Stopping Process MDM at line $linecount"
                        $ProcessMDM = $False
                     }

                     if ($ProcessErrorLog ) {
                        "Stopping Process Error Log at line $linecount"
                        $ProcessErrorLog = $False
                     }

              
                } elseif ($ProcessTotals) {
                   
                    $source = $input[0]
                    $target =   $input[1]
                    $messages =  $input[2]
                   # $source + " -> " + $target + " = " + $messages

                    if ($source -eq "MEDITECH.INBOUND.FILE.SBART" -or $source -eq "MEDITECH.INBOUND.FILE.ED" -or $source -eq "MEDITECH.INBOUND.FILE.INPATIENT")  {
                        $meditech_total_inbound += $messages
                        $total_inbound_messages += $messages
                    } elseif ($source -eq "CITO.INTERNAL.SQL" -and $target -eq "CITO.INBOUND.DOCUMENTPROCESSOR" ) {
                         $cito_total_inbound = $messages
                    } elseif ($target -eq "CITO.OUTBOUND.TCP.HL7.MDM") {
                        $cito_total_outbound = $messages
                    } elseif ($source -eq "MEDITECH.DOCUMENT.INBOUND.DOCUMENTCONVERTER" -and $target -eq "ENS.ALERT" ) {
                        $meditech_total_error = $messages
                    } elseif ($source -eq "MEDISEC.INBOUND.FILE"  ) {
                        $medisec_total_inbound = $messages
                        $total_inbound_messages += $messages
                    } elseif ($source -eq "DICTATE.INBOUND.FILE"  ) {
                        $dictate_total_inbound = $messages
                        $total_inbound_messages += $messages
                    } elseif ($source -eq "INFOFLEX.INBOUND.FILE" ) {
                        $infoflex_total_inbound = $messages
                        $total_inbound_messages += $messages
                    } elseif ($source -eq "MEDITECH.DOCUMENT.OPERATION.GENERATEPDF" ) {
                        $meditech_total_pdf = $messages
                    } elseif ($source -eq "Dictate.Inbound.DocumentProcessor" -and $target -eq "ENS.ALERT") {
                        $dictate_total_errors = $messages
                    } elseif ($source -eq "Infoflex.Inbound.DocumentProcessor" -and $target -eq "ENS.ALERT") {
                        $infoflex_total_errors = $messages
                    } elseif ($source -eq "Medisec.Inbound.DocumentProcessor" -and $target -eq "ENS.ALERT") {
                        $medisec_total_errors = $messages
                    } elseif ($source -eq "Silhouette.Inbound.File"  ) {
                        $Silhouette_total_inbound = $messages
                        $total_inbound_messages += $messages
                    } elseif ($source -eq "Silhouette.Inbound.DocumentProcessor" -and $target -eq "ENS.ALERT") {
                        $Silhouette_total_errors = $messages
                    } elseif ($source -eq "Vitaldata.Inbound.File"  ) {
                        $Vitaldata_total_inbound = $messages
                        $total_inbound_messages += $messages
                    } elseif ($source -eq "Vitaldata.Inbound.DocumentProcessor" -and $target -eq "ENS.ALERT") {
                        $Vitaldata_total_errors = $messages

                    




                    } else {
                        #$source + " -> " + $target + " = " + $messages
                    }
                } elseif ($ProcessIdentifiers) {
                    if($input -ne $null) {
                    
                        $index = $input[1]
                        $value = $input[0]
                        
                        $Sessions_Messageids[$index] = $value
                    }

                } elseif ($ProcessPDF) {
                    if($input -ne $null) {
                    
                        $index = $input[1]
                        $value = $input[0]
                        
                        $Sessions_PDF[$index] = $value
                    }

                } elseif ($ProcessErrorLog) {
                    if($input -ne $null) {
                        if ($input[1] -eq "RTGTIE.Cito.Process.DocumentProcessor" -and $input[2] -like "*RTGTIE7064*") {

                            $errorSessions += $input[0]
                        }
                    }


                }  elseif ($ProcessMDM) {
                    
                     if (($input[0] -as [int]) -is [int]) {

                
                    $session = $input[0]
                    $sessions += $session
                    $line = $input[1]
                    $i++
                

                } else {
                    $line = $input[0]
                }
           

                if ($line -eq $null) {Continue}

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
                    $MessageId = $hl7[9]
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
                            $messageids +=$MessageId
                         } else {
                            $populated++
                            $PDFProcessed = $True

                         }
                    }
            
                }
                }
            }
        }
        "____________________________________"
        "Inbound $Log"


    #    if($dictate_total_inbound -gt 0) {
            "Messages from Dictate`t`t$dictate_total_inbound`twith $dictate_total_errors errors identified"
         
    #    }

    #   if($infoflex_total_inbound -gt 0) {
            "Messages from Infoflex`t`t$infoflex_total_inbound`twith $infoflex_total_errors errors identified"
        
    #    }


     #   if($medisec_total_inbound -gt 0) {
            "Messages from Medisec`t`t$medisec_total_inbound`twith $medisec_total_errors errors identified"
           
       # }


        # if($meditech_total_inbound -gt 0) {
            "Messages from Meditech:`t`t$meditech_total_inbound`twith $meditech_total_pdf pdfs created and $meditech_total_error non-electronic"
      #  }


       # if($Silhouette_total_inbound -gt 0) {
            "Messages from Silhouette`t$Silhouette_total_inbound`twith $Silhouette_total_errors errors identified"
            if ($Silhouette_total_errors -gt 0) {
                "Processing errors $Silhouette_total_errors"
            }
      #  }


      #  if($Vitaldata_total_inbound -gt 0) {
            "Messages from Vitaldata`t`t$Vitaldata_total_inbound`twith $Vitaldata_total_errors errors identifiedd"
            if ($Vitaldata_total_errors -gt 0) {
                "Processing errors $Vitaldata_total_errors"
            }
     #   }

        "Total inbound messages`t`t$total_inbound_messages"


       

        
        
       

        "____________________________________"
        "CITO $Log"


         $total = $populated + $empty 
         "Messages from Cito Database:`t$cito_total_inbound"
         "Total MDM Messages:`t`t`t`t$cito_total_outbound"

         
        
         $MDMdiscrepancy =  $cito_total_inbound - $cito_total_outbound 
       
         "Discrepancy :`t`t`t`t`t$MDMdiscrepancy"
         "MDM Messages with Empty OBX:`t$empty" 
         "____________________________________"
         ""

       #  $Sessions_Messageids
       $Script = "$Temp\Restore.ps1"
       if (Test-Path $Script) {Remove-Item $Script}

       ForEach ($session in $errorSessions) {

         $Pdf = $Sessions_PDF[$session]
         if ($null -ne $Pdf) {
            $pdf_exists =  Test-Path $Pdf
            if (!$pdf_exists) {
                $fileRef  = $Pdf.Split("_")[0].Split("\")[-1]
                $fileRef
                $search = "$fileRef*"

                $Archive = "\\uhdbfs\healthshare\Meditech\Live\Archive\"
                $FileCount = 0
                Get-ChildItem  $Archive  | Where-Object {$_.Name -like "$search" } | ForEach {
                    $FileCount++
                    $ArchiveFile = $_.FullName
                }

                if ($FileCount -eq 1) {
                    $target = "\\uhdbfs\healthshare\Meditech\Live\ED\$fileRef"
                    $copyText = "Copy-Item -Path $ArchiveFile -Destination $target"
                    Add-Content -Path $Script $copyText

                } else {
                    "Unable to restore $search"
                }
            }
         
          }
        }

    }


     

} catch {
    "-----------------------ERROR---------------------------"
    "Processing line $linecount"
    $_
    "-------------------------------------------------------"
} Finally {
    if ($null -ne $reader) {
        $reader.Close()
        $reader.Dispose()
    }
}