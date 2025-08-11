<#
.SYNOPSIS
    This script processes SQL log files to identify and document specific alert conditions.

.DESCRIPTION
    The script reads a SQL log file, processes each line to extract relevant information, and checks for specific alert conditions.
    It then searches for corresponding files in designated archive directories and logs the results to an output file.

.PARAMETERS
    None

.EXAMPLE
    .\RTGXCHAlertsAll.ps1
    This command runs the script and processes the SQL log file to identify and document alert conditions.
Get-ChildItem -Path  "\\citodataclu\Cito_AFC$\Import_eNotes\Infoflex\Archive" | Where-Object {$_.Name -like "*150038*"}

#>


$SQLResult = "C:\Synanetics\SQL\RTGXCHAlertsAll.log"

$ArchiveList = @{
    "RTGXCH.Dictate.Process.DocumentProcessor" = "\\citodataclu\Cito_AFC$\Import_eNotes\Derby Dictate\Archive"
    "RTGXCH.Infoflex.Process.DocumentProcessor" = "\\citodataclu\Cito_AFC$\Import_eNotes\Infoflex\Archive"
    "RTGXCH.Medisec.Process.DocumentProcessor" = "\\citodataclu\Cito_AFC$\Import_eNotes\Burton Letters\Archive"
    "RTGXCH.Meditech.Document.Process.DocumentConverter" = "\\uhdbfs\healthshare\Meditech\Live\SBART\Archive"
    "RTGXCH.Silhouette.Process.DocumentProcessor" = "\\citodataclu\Cito_AFC$\Import_eNotes\Silhouette\Archive"
    "RTGXCH.Vitaldata.Process.DocumentProcessor" = "\\citodataclu\Cito_AFC$\Import_eNotes\Vitaldata\Archive"
}


try {
    Clear-Host
    if ($null -ne $reader) {
        $reader.Close()
        $reader.Dispose()
    }



    $reader = New-Object System.IO.StreamReader($SQLResult)
    if ($null -ne $reader) {
        $Searching = $False
        while (!$reader.EndOfStream) {
            $line = $reader.ReadLine()
            $result = $line.Split("`t")

            $id = $result[0]
            if ($id -le 62765476) {Continue}
            if ($Searching -eq $True -and $result[0] -ne "") {
                #"|"+$result[2]+"|"
                if ($null -eq $result[2]) {Continue}
                $text = $result[2].Split(" ")

         
                $text = ($result[2].Split(":"))
                $File = $text[0]


                $Code = $File.Split(" ")[0].Replace('"',"")

                if ($Code -eq "RTGXCH703") {Continue}
                if ($Code -eq "RTGXCH1411") {Continue}
                #Ignore BadgerNet
                if (($Code -eq "RTGXCH1608") -or ($result[3] -eq "RTGXCH.BadgerNet.Process.MessageProcessor")) {Continue}
                #Ignore TPro
                if ($Code -eq "RTGXCH1503") {Continue}
                if ($Code -eq "RTGXCH1506") {Continue}

                $Processor = $result[5]
                $DateTime = $result[3]
                $Archive = $ArchiveList[$Processor]

                    
                $File = $File.Replace("RTGXCH1404 - Converting Infoflex document file ","")
                $File = $File.Replace("RTGXCH1304 - Converting Vitaldata document file ","")
                $File = $File.Replace("RTGXCH1204 - Converting Dictate document file ","")
                $File = $File.Replace("RTGXCH1004 - Converting Medisec document file ","")
                $File = $File.Replace("RTGXCH1101 - Opening Silhouette wif file ","")
                $File = $File.Replace(" to pdf has failed with error","")
                $File = $File.Replace(" failed with error","")

                $baseName = $File.Split("\")[-1]
                $Dir =  $File.Replace($baseName,"")


                $wifFile = ""
                $docFile = ""
                $wifsearch = $baseName.Split(".")[0]+".*"
                $Reference = $baseName.Split(".")[0]

                # $CheckList = @("B000992293120240618162453","B001351681120240628095700","B000891980120240822102236")
                 
                #  if ($Reference -notin  $CheckList) {Continue}
                    
                if (Test-Path $Archive) {
                    
                        
                    $wifDestination = $Dir+$baseName.Split(".")[0]+".wif"
                        
                    $ArchivedFiles = @()
                    Get-ChildItem $Archive | Where-Object {$_.Name -like $wifsearch} | ForEach-Object {
                                
                            $ArchivedFiles += $_
                            #$wifFile = $_.FullName  
                         
                           
                               
                    }

                    $Text = ""
                    if ($ArchivedFiles.Count -eq 0) {
                        $Text = $DateTime + "," + $Processor + "," + $ArchiveList[$Processor] + ","+ $Reference + "," + $ArchivedFiles.Count
                    } else {
                        $Text = $DateTime + "," + $Processor + "," + $ArchiveList[$Processor] + ","+ $Reference + "," + $ArchivedFiles.Count
                        foreach ($ArchivedFile in $ArchivedFiles) {
                            $Text = $Text + "," + $ArchivedFile.FullName + "," +  $ArchivedFile.CreationTime
                        }



                    }
                    $Text
                    $Output = "C:\Synanetics\Scripts\Output\RTGXCHAlertsAll.dat"
                    Add-Content -Path $Output $Text

                    <#
                    $docsearch = $baseName.Split(".")[0].Replace("_"," ")     +".doc*"
                    $docfDestination = $Dir+$baseName.Split(".")[0]+".doc"

                    if ($wifFile -ne "") {

                        # "Restore $wifsearch"
                        # Copy-Item $wifFile -Destination $wifDestination
                    } else {
                        "Failed " + $wifsearch
                        ForEach ($Key in   $ArchiveList.Keys) {
                            #  "The value of '$Key' is: $($ArchiveList[$Key])"


                        }

                    }
                    #>
                    
                } else {
                    $Archive + " does not exist for "+$File
             

            } 
                    
                   


            }
            if ($result[0] -eq "ID") {
                $Searching = $True
            } elseif  ($result[0] -eq "") {
                $Searching = $False 
            }
        }
    }
    $reader.Close()
    $reader.Dispose()
} Catch {
    "Error"
    $_
    $line
    $result[3]


} finally {
    "Done"
}



<#
$SQLFiles = @("C:\Synanetics\SQL\RTGXCHAlerts.log", "C:\Synanetics\SQL\RTGXCHAlerts_Unsupported.log")

Try {
    cls
    ForEach ($SQLFile in $SQLFiles) {
        if (Test-Path -Path $SQLFile) {
            Remove-Item $SQLFile
        }  else {
             $SQLFile + " does not exist"
        }
    }
} Catch {
    $_
} Finally {


}

#>
