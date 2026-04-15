function ConvertFrom-WordToPDF {

<# 
 
.SYNOPSIS 

ConvertFrom-WordToPDF converts Microsoft Word documents to PDF files. 
 
.DESCRIPTION 

The cmdlet converts file and saves as pdf in the Destination folder.
 
.PARAMETER SourceFile
 
Mandatory. Enter the name of your Microsoft Word document.
 
.PARAMETER DestinationFolder

Mandatory. Enter the Destination folder to save the created PDF documents.

.EXAMPLE 

ConvertFrom-WordToPDF -SourceFile C:\Temp\word.docx -DestinationFolder C:\Temp
 
.NOTES 
Author: Andrew Thompson
Email: andrew@synanetics.com
 
#>

[CmdletBinding()]

param
(
 
[Parameter (Mandatory=$true,Position=0)]
[String]
$SourceFile,
 
[Parameter (Mandatory=$true,Position=1)]
[String]
$DestinationFolder

)
    If ((Test-Path '$SourceFile') -eq $false) {
    
    throw "Error. Source Folder $SourceFile not found." } 

    If ((Test-Path '$DestinationFolder') -eq $false) {
    
    throw "Error. Destination Folder $DestinationFolder not found." } 
    
    $file = Get-ChildItem -Path '$SourceFile' -ErrorAction Stop
    ''
    Write-Warning "Converting Files to PDF ..."
    '' 
	$i = 0
    $word = New-Object -ComObject word.application
    $word.visible = $false 
	$word.DisplayAlerts = [Microsoft.Office.Interop.Word.WdAlertLevel]::wdAlertsNone # disable alerts
	$word.AutomationSecurity = "msoAutomationSecurityForceDisable"
    #foreach ($f in $files) {
		$name = [System.IO.Path]::ChangeExtension($file.Fullname, "pdf")
        $doc = $word.documents.open($file.FullName,$false,$false,$false)
		
		# Instantiate a timespan and a stopwatch to exit if script runs for more than 10 seconds
		# 
		$maxWaitTimeSeconds = 600
		$starttime = Get-Date
		
        # Use ExportAsFixedFormat function.
        # See: https://learn.microsoft.com/en-us/office/vba/api/word.document.exportasfixedformat

        # Parameters:
        # OutputFileName, ExportFormat, OpenAfterExport, OptimizeFor, Range, From
        # To, Item, IncludeDocProps, KeepIRM, CreateBookmarks, DocStructureTags
        # BitmapMissingFonts, UseISO19005_1
		Do {
            $doc.ExportAsFixedFormat(
               $name,
               [Microsoft.Office.Interop.Word.WdExportFormat]::wdExportFormatPDF,
               $false,
               [Microsoft.Office.Interop.Word.WdExportOptimizeFor]::wdExportOptimizeForOnScreen,
               [Microsoft.Office.Interop.Word.WdExportRange]::wdExportAllDocument,
               0,
               0,
               [Microsoft.Office.Interop.Word.WdExportItem]::wdExportDocumentContent,
               $true,
               $true,
               [Microsoft.Office.Interop.Word.WdExportCreateBookmarks]::wdExportCreateWordBookmarks,
               $true,
               $false
            )    
			$result = Test-Path '$name'
			if (-not $result) {
              Start-Sleep -Milliseconds 500
            }
		} while (-not $result -and ((Get-Date) - $starttime).TotalSeconds -lt $maxWaitTimeSeconds)
		
        if ($result) {
			$doc.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges) # discard changes and close without prompting to save
			Move-Item -Path '$name' -Destination '$DestinationFolder' -force
			Write-Output "$($file.Name) converted to PDF"
			$i++
		}
		Else {
			$doc.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges) # discard changes and close without prompting to save
			Write-Output "$($file.Name) NOT converted to PDF, as action did not complete before timeout period."
			throw 'Action did not complete before timeout period.'
		}
    #}
    ''
    Write-Output "$i file(s) converted."
	# clean up Com object after use
	[System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    $word.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($word) | Out-Null
    Remove-Variable word
	return $result
}



