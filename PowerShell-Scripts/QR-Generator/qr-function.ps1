
<#PSScriptInfo

.VERSION 0.1

.GUID 3d969f6d-2454-43b1-b2a0-55273d2d743b

.AUTHOR ScottishDex

.COMPANYNAME

.COPYRIGHT

.TAGS

.LICENSEURI

.PROJECTURI

.ICONURI

.EXTERNALMODULEDEPENDENCIES 

.REQUIREDSCRIPTS

.EXTERNALSCRIPTDEPENDENCIES

.RELEASENOTES


.PRIVATEDATA

#>

<# 

.DESCRIPTION 
 User can use this function to generate a QR code from a URL. The QR code will be saved as a PNG file on the user's desktop. The script uses an online API to generate the QR code, so it is important that the URL is not sensitive or private. 

#> 


function New-QRCode {


    
    Write-Host "This script uses an online API to generate a QR code from a URL, so please ensure your URL is not sensitive or private."
    $promptText = "Please enter the URL you want to encode in the QR code"
    $dataInput = Read-Host -Prompt $promptText

    if ([string]::IsNullOrWhiteSpace($dataInput)) {
        Write-Error "No data provided. Aborting."
        return # Exit the function
    }

    $safeFileName = $dataInput -replace '[^a-zA-Z0-9]', ''
    $outputFile = "$env:USERPROFILE\Desktop\$($safeFileName).png"

    Add-Type -AssemblyName System.Web
    $encodedText = [System.Web.HttpUtility]::UrlEncode($dataInput)
    $qrUrl = "https://api.qrserver.com/v1/create-qr-code/?size=300x300&data=$encodedText"

    Write-Host "Generating QR code for: $dataInput" -ForegroundColor Cyan

    try {
        Invoke-WebRequest -Uri $qrUrl -OutFile $outputFile -UseBasicParsing -ErrorAction Stop
        Write-Host "`nQR code saved to: $outputFile" -ForegroundColor Green
    }
    catch {
        write-Error "Failed to generate QR code. $_"
    }
}