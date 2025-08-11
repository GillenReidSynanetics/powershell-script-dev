<#
.SYNOPSIS
    Processes log file entries and copies PDF files based on the log data.

.DESCRIPTION
    This script reads a log file, processes each line to extract PDF file references, 
    and generates a PowerShell script to copy the identified PDF files to a specified destination.

.PARAMETER Log
    The path to the log file that contains the entries to be processed.

.PARAMETER Destination
    The directory where the PDF files will be copied to.

.PARAMETER Temp
    The directory where the temporary script will be created.

.PARAMETER PDF_In
    The directory where the input PDF files are located.

.PARAMETER PDF_Out
    The directory where the output PDF files will be stored.

.NOTES
    The script creates a temporary PowerShell script to perform the copy operations.
    It ensures that the temporary script is removed if it already exists.
    The script handles the closing and disposing of the StreamReader object properly.

.EXAMPLE
    .\EXCHANGE_CITO_RTGTIE701_Processe.ps1
    This command runs the script to process the log file and generate the copy script.

#>
try {
    cls
    $Log = "C:\Synanetics\SQL\EXCHANGE_CITO_RTGTIE701.log"
    $Destination = "C:\Synanetics\Scripts\Files"
    $Temp = "C:\Synanetics\Scripts\Temp"


    $PDF_In = "C:\Synanetics\Scripts\Files\PDF\In"
    $PDF_Out = "C:\Synanetics\Scripts\Files\PDF\Out"



    $Script = "$Temp\CopyPDF.ps1"
    if (Test-Path $Script) {Remove-Item $Script}

    if ($null -ne $reader) {
        $reader.Close()
        $reader.Dispose()
    }
    $reader = New-Object System.IO.StreamReader($Log)
    $readline = $False
    if ($reader -ne $null) {
        while (!$reader.EndOfStream) {
            $input = $reader.ReadLine().Split("`t")
            if ($input[0] -eq "Guid") {
                $readline = $True
            } elseif ($input[0] -like "*Rows(s) Affected") {
                $readline = $False
            } elseif ($readline) {
                if ($input -ne $null) {
                    $pdf = $input[1]
                  #  $pdf
              
                    $fileRef  = $pdf.Split("_")[0].Split("\")[-1]
                    
                    $pdfExists = Test-Path $pdf
                    

                    $search = "$fileRef*"
                    $search

                    
                    $FileCount = 0
               
                    Get-ChildItem  $PDF_In  | Where-Object {$_.Name -like "$search" } | ForEach {
                    "Found"
                        $FileCount++
                        $ArchiveFile = $_.FullName
                    }
                    if ($FileCount -eq 1) {
                       "Copy"
                       # $target = "$Destination\$fileRef"
                        $copyText = "Copy-Item -Path $ArchiveFile -Destination $Pdf"
                       
                        Add-Content -Path $Script $copyText
                    }
                    
                       
                }
            }

        }
    }

} Catch { 
    $_
} Finally {
    if ($null -ne $reader) {
        $reader.Close()
        $reader.Dispose()
    }

}