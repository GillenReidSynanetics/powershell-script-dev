# decrypt.ps1
# Decrypts a file encrypted with AES using a password and a separate IV file

Add-Type -AssemblyName System.Windows.Forms

# Get password
$password = Read-Host "Enter the password used for encryption"
if ($password.Length -lt 8) {
    Write-Error "Password must be at least 8 characters."
    exit
}

# Derive the AES key from password
$key = (New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($password))

# Prompt user to select encrypted file
$fileDialog = New-Object System.Windows.Forms.OpenFileDialog
$fileDialog.InitialDirectory = [Environment]::GetFolderPath("Desktop")
$fileDialog.Filter = "Encrypted files (*.enc)|*.enc|All files (*.*)|*.*"
$fileDialog.Title = "Select the encrypted file"

if ($fileDialog.ShowDialog() -ne [System.Windows.Forms.DialogResult]::OK) {
    Write-Host "No file selected. Exiting."
    exit
}

$EncryptedFile = $fileDialog.FileName
$IVFile = "$EncryptedFile".Replace(".enc", ".iv")
$OutputFile = "$EncryptedFile".Replace(".enc", ".decrypted")

# Validate file presence
if (-not (Test-Path $IVFile)) {
    Write-Error "Matching IV file not found: $IVFile"
    exit
}

# Load encrypted content and IV
$IV = [System.IO.File]::ReadAllBytes($IVFile)
$EncryptedContent = [System.IO.File]::ReadAllBytes($EncryptedFile)

# Set up AES for decryption
$Aes = [System.Security.Cryptography.Aes]::Create()
$Aes.Key = $key
$Aes.IV = $IV

# Decrypt
$Decryptor = $Aes.CreateDecryptor()
try {
    $DecryptedBytes = $Decryptor.TransformFinalBlock($EncryptedContent, 0, $EncryptedContent.Length)
} catch {
    Write-Error "Decryption failed: Incorrect password or corrupted file."
    exit
}

# Save decrypted output
[System.IO.File]::WriteAllBytes($OutputFile, $DecryptedBytes)

Write-Host "Decryption complete!"
Write-Host "Decrypted file saved as: $OutputFile"
