$secureCredentials = Import-Clixml -Path "C:\Users\GillenReid\Desktop\credentials.xml"
Register-PSResourceRepository -Name PSGallery -Uri 'https://www.powershellgallery.com/api/v2' -Trusted -ErrorAction SilentlyContinue
Publish-PSResource -Path 'C:\Users\GillenReid\Documents\Repos\Script-Lab\powershell-script-dev\Troubleshooting\PS-Gallery\qr-function.ps1' -Repository PSGallery -ApiKey $secureCredentials -Verbose
