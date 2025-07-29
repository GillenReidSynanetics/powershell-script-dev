# encryption.ps1
# Encrypts a file using AES and a user-provided password.

Add-Type -AssemblyName System.Windows.Forms

# Get password
$password = Read-Host "Enter the password for encryption (at least 8 characters)"
if ($password.Length -lt 8) {
    Write-Error "Password must be at least 8 characters."
    exit
}

# Derive encryption key from password
$key = (New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($password))

# Open file dialog to select file
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
$fileDialog.Filter = "All files (*.*)|*.*"
$fileDialog.Title = "Select the file you wish to encrypt"

if ($fileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No file selected. Exiting."
    exit
}

$InputFile = $fileDialog.FileName
$OutputFile = "$InputFile.enc"
$IVFile = "$InputFile.iv"

# Read original content
$Content = [System.IO.File]::ReadAllBytes($InputFile)

# AES setup
$Aes = [System.Security.Cryptography.Aes]::Create()
$Aes.Key = $key
$Aes.GenerateIV()
$IV = $Aes.IV

# Save IV for decryption later
[System.IO.File]::WriteAllBytes($IVFile, $IV)

# Encrypt
$Encryptor = $Aes.CreateEncryptor()
$EncryptedContent = $Encryptor.TransformFinalBlock($Content, 0, $Content.Length)

# Save encrypted file (IV is not prepended here — stored separately)
[System.IO.File]::WriteAllBytes($OutputFile, $EncryptedContent)

Write-Host "Encryption complete!"
Write-Host "Encrypted file: $OutputFile"
Write-Host "IV saved as: $IVFile"
