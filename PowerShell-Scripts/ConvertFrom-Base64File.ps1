<#
.SYNOPSIS
    Decodes a Base64-encoded file and writes the output to a specified file.

.DESCRIPTION
    This script prompts the user to select a file containing a Base64-encoded string using a file dialog.
    It then decodes the Base64 string and writes the resulting bytes to an output file at a specified path.
    Error handling is included to manage invalid file selections and decoding errors.

.PARAMETER None
    The script does not accept parameters; it uses a file dialog for file selection and a hardcoded output path.

.NOTES
    - Requires Windows Forms to be available (runs on Windows PowerShell).
    - Update the $outputPath variable to specify the desired output file location and name.
    - The input file should contain only the Base64 string (no extra whitespace or newlines).

.EXAMPLE
    Run the script. When prompted, select a file containing a Base64 string.
    The decoded file will be saved to the path specified in $outputPath.

#>


Add-Type -AssemblyName system.Windows.Forms

$null = [System.Windows.Forms.Application]::EnableVisualStyles()
$form = New-Object System.Windows.Forms.Form
$form.TopMost = $true
$form.WindowState = 'Minimized'
$form.ShowInTaskbar = $false
$form.Show()


$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
$openFileDialog.Filter = "All Files (*.*)|*.*"
$openFileDialog.Title = "Select a file containing Base64 string"

# Show dialog
if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $FilePath = $openFileDialog.FileName
    Write-Host "✅ File selected: $FilePath"
} else {
    Write-Error "❌ No file selected. Exiting script."
    exit
}
$outputPath = "$PSScriptRoot\DecodedFile.txt" # Path to save the output file
{ try {

        $base64String = Get-Content -path $FilePath -Raw
        $fileBytes = [System.Convert]::FromBase64String($base64String)
        [System.IO.File]::WriteAllBytes($outputPath, $fileBytes)

    }
    catch {
        Write-Error "An error occurred: $_"
        Write-Host "Please check the file path and ensure the base64 string is valid."
    }
    finally {
        Write-Host "Process completed. File has been decoded and saved to $outputPath."
        Read-Host "Press Enter to exit"
    }
    
}