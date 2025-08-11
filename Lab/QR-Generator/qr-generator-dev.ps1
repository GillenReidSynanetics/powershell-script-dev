<#
.SYNOPSIS
Generates a QR code image from a user-provided URL and saves it to the desktop.

.DESCRIPTION
This script prompts the user to enter a URL, encodes it for safe transmission, and generates a QR code using an online API (api.qrserver.com). The resulting QR code image is saved to the user's desktop with a filename based on the encoded URL. The script includes error handling for both the web request and file operations.

.PARAMETER texttoEncrypt
The URL entered by the user to be encoded into the QR code.

.OUTPUTS
A PNG image file containing the generated QR code, saved to the user's desktop.

.EXAMPLE
PS> .\qr-generator.ps1
Please enter the URL you want to encode in the QR code: https://www.example.com
QR code saved to: C:\Users\<User>\Desktop\https%3a%2f%2fwww.example.com.png

.NOTES
- Requires internet access to contact the QR code generation API.
- The output file name is URL-encoded, which may result in long or complex file names.
- Tested on Windows PowerShell.
#>

# Variables and user entry for QR code generation


function New-QRfromURL {
    param (
        [string]$texttoEncrypt
    )

    if ([string] $texttoEncrypt) {
        Write-Error "No URL provided. Exiting script."
        exit 1
    }
    
}



$texttoEncrypt = Read-Host "Please enter the URL you want to encode in the QR code:"

if ($texttoEncrypt -ne "") {
    Write-Host "Generating QR code for: $texttoEncrypt" -ForegroundColor Cyan
} else {
    Write-Error "No URL provided. Exiting script."
    exit 1
}
Add-Type -AssemblyName System.Web 
$encodedText = [System.Web.HttpUtility]::UrlEncode($texttoEncrypt)
$qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$encodedText"

# Output path for the QR code image
$outputPath = "$env:USERPROFILE\Desktop\$encodedText.png"

# error handling for URL and file operations
try {
    Invoke-WebRequest -Uri $qrUrl -OutFile $outputPath -UseBasicParsing
    Write-Host "`nQR code saved to: $outputPath" -ForegroundColor Green
} catch {
    Write-Error "Failed to generate QR code. $_"
}
