$Password = "MySecretPassword"
$Key = (New-Object Security.Cryptography.SHA256Managed).ComputeHash([Text.Encoding]::UTF8.GetBytes($Password))

$InputFile = "C:\path\to\file.txt.enc"
$Data = [System.IO.File]::ReadAllBytes($InputFile)

$IV = $Data[0..15]
$EncryptedContent = $Data[16..($Data.Length - 1)]

$Aes = [System.Security.Cryptography.Aes]::Create()
$Aes.Key = $Key
$Aes.IV = $IV

$Decryptor = $Aes.CreateDecryptor()
$Decrypted = $Decryptor.TransformFinalBlock($EncryptedContent, 0, $EncryptedContent.Length)

[System.Text.Encoding]::UTF8.GetString($Decrypted)
# Save the decrypted content to a file
$OutputFile = "C:\path\to\decrypted_file.txt"
[System.IO.File]::WriteAllBytes($OutputFile, $Decrypted)