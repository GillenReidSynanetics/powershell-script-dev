<#
.SYNOPSIS
    Converts a selected file to a Base64-encoded string and saves the result to a text file.

.DESCRIPTION
    This script opens a file selection dialog for the user to choose a file. It reads the file as bytes,
    converts the contents to a Base64 string, and writes the output to 'ConvertedFileBase64.txt' in the script's directory.
    The script provides user feedback on file selection and handles errors gracefully.

.PARAMETER None
    The script does not accept parameters; it uses a GUI dialog for file selection.

.OUTPUTS
    Writes a Base64-encoded string to 'ConvertedFileBase64.txt' in the script's directory.

.NOTES
    - Requires Windows PowerShell with access to Windows Forms.
    - The output file will be overwritten if it already exists.
    - The script must have permission to read the selected file and write to the output directory.

.EXAMPLE
    Run the script. Select a file when prompted. The Base64-encoded content will be saved to 'ConvertedFileBase64.txt'.

#>


Add-Type -AssemblyName system.Windows.Forms

$openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
$openFileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
$openFileDialog.Filter = "All Files (*.*)|*.*"
$openFileDialog.Title = "Select a base 64 file to convert"

# Show dialog
if ($openFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
    $FilePath = $openFileDialog.FileName
    Write-Host "✅ File selected: $FilePath"
}
else {
    Write-Error "❌ No file selected. Exiting script."
    exit
}

try {
    $outputPath = "$PSScriptRoot\ConvertedFileBase64.txt" # Path to save the output file
    $fileBytes = [System.IO.File]::ReadAllBytes($FilePath)

    # Process for conversion
    $base64String = [System.Convert]::ToBase64String($fileBytes)
    # Output the Base64 string to a file
    Set-Content -Path $outputPath -Value $base64String
}
catch {
    Write-Error "An error occurred: $_"
    Write-Host "Please check the file path and ensure the input file exists and is accessible."
}
finally {
    Write-Host "Conversion process completed. The Base64 string has been saved to $outputPath."
}
read-host "Press Enter to exit"
exit