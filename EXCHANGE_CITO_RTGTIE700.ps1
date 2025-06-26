<#
.SYNOPSIS
    This script processes a log file and generates a PowerShell script to copy specific files from an archive to a destination directory.

.DESCRIPTION
    The script reads a log file located at "C:\Synanetics\SQL\EXCHANGE_CITO_RTGTIE700.log" and processes its content to identify specific PDF files.
    If the PDF file does not exist in the specified location, it searches for the file in an archive directory.
    If exactly one matching file is found in the archive, it generates a PowerShell script to copy the file to the destination directory.

.PARAMETERS
    None

.NOTES
    The script uses a temporary file "Copy.ps1" to store the copy commands.
    The log file is expected to have tab-separated values with specific keywords to identify relevant lines.
    The script handles exceptions and ensures that the StreamReader object is properly disposed of in the Finally block.

.EXAMPLE
    To run the script, simply execute it in a PowerShell session:
    .\EXCHANGE_CITO_RTGTIE700.ps1
#>
try {
    Clear-Host
    $Log = "C:\Synanetics\SQL\EXCHANGE_CITO_RTGTIE700.log"
    $Destination = "C:\Synanetics\Scripts\Files\MTDD"
    $Temp = "C:\Synanetics\Scripts\Temp"

    $Script = "$Temp\Copy.ps1"
    if (Test-Path $Script) {Remove-Item $Script}

    if ($null -ne $reader) {
        $reader.Close()
        $reader.Dispose()
    }
    $reader = New-Object System.IO.StreamReader($Log)
    $readline = $False
    if ($null -ne $reader) {
        while (!$reader.EndOfStream) {
            $lineInput = $reader.ReadLine().Split("`t")
            if ($lineInput[0] -eq "Guid") {
                $readline = $True
            } elseif ($lineInput[0] -like "*Rows(s) Affected") {
                $readline = $False
            } elseif ($readline) {
                if ($null -ne $lineInput) {
                    $pdf = $lineInput[1]
                    $fileRef  = $pdf.Split("_")[0].Split("\")[-1]
                    $pdfExists = Test-Path $pdf
                    if (!$pdfExists) {
                        "$pdf  $pdfExists"

                        $search = "$fileRef*"

                        $Archive = "\\uhdbfs\healthshare\Meditech\Live\Archive\"
                        $FileCount = 0
                        Get-ChildItem  $Archive  | Where-Object {$_.Name -like "$search" } | ForEach-Object {
                            $FileCount++
                        }
                        if ($FileCount -eq 1) {
                       
                            $target = "$Destination\$fileRef"
                            $copyText = "Copy-Item -Path $ArchiveFile -Destination $target"
                            Add-Content -Path $Script $copyText
                        }

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