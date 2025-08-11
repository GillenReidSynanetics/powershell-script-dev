
# Secure Credential Process Script
# When loading an API key - always paste it as the password, the username acts as a label.
# This script securely stores and retrieves credentials using PowerShell's secure string capabilities.
$credentials = Get-Credential "Please enter your credentials for secure processing"
$credentials | Export-Clixml -Path "$env:USERPROFILE\Desktop\credentials.xml"
$secureCredentials = Import-Clixml -Path "$env:USERPROFILE\Desktop\credentials.xml"

$