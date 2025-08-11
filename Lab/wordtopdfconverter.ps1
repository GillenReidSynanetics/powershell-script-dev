# variable to hold the path to the document to be converted
$documentPath = "$PSScriptRoot\converter.docx"
$pdfPath = "$PSScriptRoot\converter.pdf"

# Check if the document exists
 if (-not (Test-Path $documentPath)) {
     Write-Error "Source document not found $documentPath"
     exit 1
}

Write-Host "Kicking off MS Word to initiate conversion" # This will take a few seconds
$word = New-Object -ComObject Word.Application # Create a new instance of Word
$word.Visible = $false # hide the Word application

write-host "Opening document $documentPath"
try {
    $document = $word.Documents.Open($documentPath) # Open the document
    $pdfFormat = 17 # PDF format constant for Word
    write-host "Saving document as PDF to $pdfPath"
    $document.SaveAs([ref] $pdfPath, [ref] $pdfFormat) # Save the document as PDF
    $document.Close() # Close the document
    $word.Quit() # Quit the Word application
}
catch {
    Write-Error "An error occurred while converting the document: $_"
    $word.Quit() # Ensure Word is closed even if an error occurs
    exit 1
} finally {
    # 4. CLEAN UP: CLOSE THE DOCUMENT AND QUIT WORD
    # This part is crucial to avoid leaving hidden Word processes running.
    if ($document) { $document.Close() }
    if ($word) { $word.Quit() }
    
    # Release the COM objects from memory
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($document) | Out-Null
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
    
    # Ensure garbage collection runs
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
}

Write-Host "Conversion complete!"