#Get-ChildItem -Path  "\\citodataclu\Cito_AFC$\Import_eNotes\Infoflex\Archive" | Where-Object {$_.Name -like "*150038*"}


<#
.SYNOPSIS
    This script processes a log file to identify and restore specific document files from an archive directory.

.DESCRIPTION
    The script reads a log file located at "C:\Synanetics\SQL\RTGXCHAlerts.log" and processes each line to identify 
    document conversion errors. If an error is found, it attempts to restore the corresponding document file from an 
    archive directory. After processing, it deletes the log files.

.PARAMETERS
    None

.EXAMPLE
    .\RTGXCHAlerts.ps1
    This command runs the script to process the log file and restore any identified document files.

.NOTES
    The script looks for specific error messages related to document conversion failures and attempts to restore 
    the original document files from an archive directory if they exist.

#>
$SQLResult = "C:\Synanetics\SQL\RTGXCHAlerts.log"


try {
    Clear-Host
    $reader = New-Object System.IO.StreamReader($SQLResult)
    if ($reader -ne $null) {
        $Searching = $False
        while (!$reader.EndOfStream) {
            $line = $reader.ReadLine()
            $result = $line.Split("`t")
            if ($Searching -eq $True -and $result[0] -ne "") {
                #"|"+$result[2]+"|"
                $text = $result[2].Split(" ")
                if ($text[0] -ne "RTGXCH703") {
                    $text = ($result[2].Split(":"))
                     $File = $text[0].Replace("RTGXCH1404 - Converting Infoflex document file ","")
                     $File = $File.Replace("RTGXCH1304 - Converting Vitaldata document file ","")
                     $File = $File.Replace("RTGXCH1004 - Converting Medisec document file ","")
                     $File = $File.Replace(" to pdf has failed with error","")
                     $baseName = $File.Split("\")[-1]
                     $Dir =  $File.Replace($baseName,"")
                     

                     $Archive = $Dir+"Archive"
                     if (Test-Path $Archive) {
                        $wifFile = ""
                        $docFile = ""
                        $wifsearch = $baseName.Split(".")[0]+".wif*"
                        $wifDestination = $Dir+$baseName.Split(".")[0]+".wif"
        
                        Get-ChildItem $Archive | Where-Object {$_.Name -like $wifsearch} | ForEach-Object {
                             $wifFile = $_.FullName
                        }

                        $docsearch = $baseName.Split(".")[0].Replace("_"," ")     +".doc*"
                        $docfDestination = $Dir+$baseName.Split(".")[0]+".doc"

                        if ($wifFile -ne "") {

                           "Restore $wifsearch"
                            Copy-Item $wifFile -Destination $wifDestination
                        }

                     } else {
                       # "No archive folder folder for "+$File

                      

                     }
                   
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

}


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
