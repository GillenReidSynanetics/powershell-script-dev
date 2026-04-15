function ConvertFrom-WordToPDF {

<# 
 
.SYNOPSIS 

Converts Microsoft Word document to PDF. 
 
.DESCRIPTION 

ConvertFrom-WordToPDF converts Microsoft Word document and saves as PDF in the Destination folder.
 
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

  Param (
    [Parameter (
      Mandatory = $true,
      Position = 0,
      HelpMessage = "File to convert"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $SourceFile,
 
    [Parameter (
      Mandatory = $true,
      Position = 1,
      HelpMessage = "Destination folder for converted file"
    )]
    [ValidateNotNullOrEmpty ()]
    [String]
    $DestinationFolder
  )

  Begin {
    $Result = $false
    $PowerShellPid = [System.Diagnostics.Process]::GetCurrentProcess() | Select-Object -ExpandProperty ID
    $ProcessStopwatch = [system.diagnostics.stopwatch]::StartNew()
  }
  Process {
    if (Test-Path -Path $SourceFile) {
      Write-EventLog -LogName Application -Source "ConvertFrom-WordToPDF" -EntryType Information -EventId 1 -Message "PID: $PowerShellPid - File $SourceFile exists"
    }
    else {
      Write-EventLog -LogName Application -Source "ConvertFrom-WordToPDF" -EntryType Error -EventId 1 -Message "PID: $PowerShellPid - File $SourceFile does not exist"
      Stop-Script 1
    }
    if (Test-Path -Path $DestinationFolder) {
      Write-EventLog -LogName Application -Source "ConvertFrom-WordToPDF" -EntryType Information -EventId 2 -Message "PID: $PowerShellPid - Directory $DestinationFolder exists"
    }
    else {
      Write-EventLog -LogName Application -Source "ConvertFrom-WordToPDF" -EntryType Error -EventId 2 -Message "PID: $PowerShellPid - Directory $DestinationFolder does not exist"
      Stop-Script 1
    }
    $ProcessStopwatch = [system.diagnostics.stopwatch]::StartNew()
    $File = Get-ChildItem -Path $SourceFile
    $MSWord = New-Object -ComObject Word.Application
    $MSWord.Visible = $false 
    $MSWord.DisplayAlerts = [Microsoft.Office.Interop.Word.WdAlertLevel]::wdAlertsNone # disable alerts
    $MSWord.AutomationSecurity = "msoAutomationSecurityForceDisable"
    try {
      $PDFName = [System.IO.Path]::ChangeExtension($File.Fullname, "pdf")
      $WordDocument = $MSWord.documents.open($File.FullName,$false,$true,$false)
      $WordDocument.ExportAsFixedFormat(
          $PDFName,
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
      $Result = Test-Path $PDFName
      if ($Result) {
        $WordDocument.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges) # discard changes and close without prompting to save
        Move-Item -Path $PDFName -Destination $DestinationFolder -force
        $ProcessStopwatch.Stop()
        $ProcessTime = [math]::Round($ProcessStopwatch.Elapsed.TotalSeconds,2)
        Write-EventLog -LogName Application -Source "ConvertFrom-WordToPDF" -EntryType Information -EventId 3 -Message "PID: $PowerShellPid - $($File.Name) converted to PDF - Duration: $ProcessTime seconds"
      }
      else {
        $WordDocument.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges) # discard changes and close without prompting to save
        $ProcessStopwatch.Stop()
        $ProcessTime = [math]::Round($ProcessStopwatch.Elapsed.TotalSeconds,2)
        Write-EventLog -LogName Application -Source "ConvertFrom-WordToPDF" -EntryType Error -EventId 3 -Message "PID: $PowerShellPid - $($File.Name) NOT converted to PDF - Duration: $ProcessTime seconds"
        throw 'Action did not complete before timeout period.'
      }
    }
    catch [System.Management.Automation.RuntimeException] {
      $WordDocument.Close([Microsoft.Office.Interop.Word.WdSaveOptions]::wdDoNotSaveChanges) # discard changes and close without prompting to save
      $ProcessStopwatch.Stop()
      $ProcessTime = [math]::Round($ProcessStopwatch.Elapsed.TotalSeconds,2)
      Write-EventLog -LogName Application -Source "ConvertFrom-WordToPDF" -EntryType Error -EventId 4 -Message "PID: $PowerShellPid - $($File.Name) NOT converted to PDF. Error: $_ - Duration: $ProcessTime seconds"
    }
    return $Result
  }
  End {
    # clean up Com object after use
    $ReleaseComObjectStopwatch =  [system.diagnostics.stopwatch]::StartNew()
    $MSWord.Quit()
    [System.Runtime.Interopservices.Marshal]::ReleaseComObject($MSWord) | Out-Null
    $ReleaseComObjectStopwatch.Stop()
    $ReleaseComObjectTime = [math]::Round($ReleaseComObjectStopwatch.Elapsed.TotalSeconds,2)
    $GCStopwatch =  [system.diagnostics.stopwatch]::StartNew()
    Remove-Variable MSWord
    $GCStopwatch.Stop()
    $GCTime = [math]::Round($GCStopwatch.Elapsed.TotalSeconds,2)
    Write-EventLog -LogName Application -Source "ConvertFrom-WordToPDF" -EntryType Information -EventId 5 -Message "PID: $PowerShellPid - COM object cleanup complete - Release COM Object Duration: $ReleaseComObjectTime seconds - Garbage Collection Duration: $GCTime seconds"
  }
}



