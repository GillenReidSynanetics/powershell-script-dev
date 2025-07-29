$password = "your_password_here"  # Replace with your actual password
$key = (New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($Password))

$Aes = [System.Security.Cryptography.Aes]::Create()
$Aes.Key = $Key
$Aes.GenerateIV()
$IV = $Aes.IV
# Save the IV to a file for later decryption
$IVFile = "C:\path\to\iv.bin"
[System.IO.File]::WriteAllBytes($IVFile, $IV)
# Encrypt the file
if (-not (Test-Path $InputFile)) {
    Write-Error "Input file does not exist: $InputFile"
    exit
}
$InputFile = "C:\path\to\file.txt"
$OutputFile = "C:\path\to\file.txt.enc"
$Content = [System.IO.File]::ReadAllBytes($InputFile)

$Encryptor = $Aes.CreateEncryptor()
$EncryptedContent = $Encryptor.TransformFinalBlock($Content, 0, $Content.Length)

# Save IV + EncryptedContent to file
[System.IO.File]::WriteAllBytes($OutputFile, $IV + $EncryptedContent)

=====================================

