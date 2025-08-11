<#
.SYNOPSIS
    Processes a SQL result log file and generates a CSV output with specific data extracted from the log.

.DESCRIPTION
    This script reads a log file generated from a SQL query, processes the data to extract specific HL7 message segments, 
    and outputs the results to a CSV file. It handles different HL7 segments such as MSH, TXA, and OBX to gather information 
    about documents and their statuses.

.PARAMETER SQLResult
    The path to the SQL result log file to be processed.

.PARAMETER Output
    The path to the CSV file where the processed data will be saved.

.NOTES
    The script checks if the output file already exists and removes it before processing. It counts the number of empty 
    and populated PDF fields and outputs these counts at the end of the script.

.EXAMPLE
    .\EXCHANGECITO.ps1
    This example runs the script and processes the default SQL result log file, saving the output to the default CSV file.

#>

param (
    [string]$SQLResult = "C:\Synanetics\SQL\EXCHANGECITO.log",
    [string]$Output = "C:\Synanetics\Scripts\Output\EXCHANGECITO.csv"
)

function Convert-HL7Log {
    param (
        [string]$SQLResult,
        [string]$Output
    )

    try {
        if (Test-Path -Path $Output) {
            Remove-Item $Output
        }

        $empty = 0
        $populated = 0
        $reader = [System.IO.StreamReader]::new($SQLResult)

        while (!$reader.EndOfStream) {
            $lineInput = $reader.ReadLine().Split("`t")
            $session = if ($lineInput[0] -as [int]) { $lineInput[0] } else { $null }
            $line = if ($session) { $lineInput[1] } else { $lineInput[0] }

            if ($null -eq $line) { continue }

            $hl7 = $line.Split("|")

            if (($hl7[0] -eq "MSH" -and $Document) -or ($hl7[0] -eq "" -and $Document)) {
                $Text = "$DateTime,$Session,$Document,$PDFProcessed"
                Add-Content -Path $Output -Value $Text
                $Document = ""
                $PDFProcessed = $False
            }

            switch ($hl7[0]) {
                "MSH" { $DateTime = $hl7[6] }
                "TXA" { $Document = $hl7[12] }
                "OBX" {
                    $Fields = $hl7[5].Split("^")
                    if ($Fields[2] -eq "PDF") {
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

        "Populated: $populated"
        "Empty: $empty"
        $total = $populated + $empty
        "Total: $total"
    }
    catch {
        "Error: $_"
    }
    finally {
        $reader.Close()
        $reader.Dispose()
    }
}

Convert-HL7Log -SQLResult $SQLResult -Output $Output
