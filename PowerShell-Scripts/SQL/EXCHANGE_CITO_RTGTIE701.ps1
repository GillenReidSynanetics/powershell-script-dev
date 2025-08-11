<#
.SYNOPSIS
    This script processes a log file and generates a PowerShell script to copy specific files from an archive to a destination directory.

.DESCRIPTION
    The script reads a log file located at "C:\Synanetics\SQL\EXCHANGE_CITO_RTGTIE701.log" and processes its content to identify specific PDF files.
    If a PDF file is not found in the specified path, it searches for the file in an archive directory.
    If exactly one matching file is found in the archive, it generates a copy command and appends it to a temporary script file.

.PARAMETERS
    None

.NOTES
    The script uses a try-catch-finally block to handle exceptions and ensure resources are properly disposed of.
    The temporary script file is created at "C:\Synanetics\Scripts\Temp\Copy.ps1".

.EXAMPLE
    To execute the script, simply run it in a PowerShell session:
    .\EXCHANGE_CITO_RTGTIE701.ps1

#>
try {
    Clear-Host
    $Log = "C:\Synanetics\SQL\EXCHANGE_CITO_RTGTIE701.log"
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