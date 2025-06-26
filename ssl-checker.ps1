<#
.SYNOPSIS
    Checks an SSL certificate file and generates a detailed HTML report.

.DESCRIPTION
    This script prompts the user to select a PEM-formatted SSL certificate file using a graphical file dialog.
    It validates the file, checks for the presence of OpenSSL, and extracts certificate details such as subject, issuer, and expiry date.
    The script then generates a styled HTML report containing the extracted information and the full certificate output, saves it to the user's Desktop, and opens it in the default web browser.

.PARAMETER certFile
    The default certificate file name (not used if file is selected via dialog). Default is "cert.pem".

.NOTES
    - Requires OpenSSL to be installed and available in the system PATH.
    - The HTML report is saved to the Desktop as "SSL-Certificate-Report.html".
    - Created by AI as the user requested HTML formatting assistance.

.EXAMPLE
    .\ssl-checker.ps1
    # Prompts for certificate file, generates and opens HTML report.

#>
param (
    [string]$certFile = "cert.pem"
)

Add-Type -AssemblyName System.Windows.Forms

# Prompt for certificate file selection using a dialog box
# =====================================
$dialog = New-Object System.Windows.Forms.OpenFileDialog
$dialog.InitialDirectory = [Environment]::GetFolderPath('Desktop')
$dialog.Filter = "PEM files (*.pem)|*.pem|All files (*.*)|*.*"
$dialog.Title = "Select a certificate file to check"

if ($dialog.ShowDialog() -eq "OK") {
    $certPath = $dialog.FileName
    Write-Host "📁 You selected: $certPath"
} else {
    Write-Host "❌ File selection cancelled."
    exit 1
}

# =====================================

# Error Handling 

# Validate file
if (-not (Test-Path $certPath)) {
    Write-Host "❌ Certificate file not found: $certPath"
    exit 1
}

# Check OpenSSL
$openssl = "openssl.exe"
if (-not (Get-Command $openssl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ OpenSSL not found in PATH."
    exit 1
}

#=====================================

# Open SSL Command to generate information on certificate.

try {
    $certInfo = & $openssl x509 -in $certPath -noout -text
    $subject  = & $openssl x509 -in $certPath -noout -subject
    $issuer   = & $openssl x509 -in $certPath -noout -issuer
    $expiry   = & $openssl x509 -in $certPath -noout -enddate
}
catch {
    Write-Host "❌ Error executing OpenSSL command: $_"
    exit 1
}

# Clean values
$subject = $subject -replace "subject=", ""
$issuer  = $issuer -replace "issuer=", ""
$expiry  = $expiry -replace "notAfter=", ""

# Output to HTML report, formatted for readability (using CSS for styling)

# Created by AI as I cant do HTML...

$htmlReport = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>SSL Certificate Report</title>
    <style>
        body {
            font-family: 'Segoe UI', sans-serif;
            background-color: #f9fafb;
            color: #333;
            padding: 40px;
        }
        .container {
            max-width: 900px;
            margin: 0 auto;
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 8px rgba(0,0,0,0.05);
            padding: 30px;
        }
        h1 {
            color: #007acc;
            margin-bottom: 20px;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
        }
        .info-grid {
            display: grid;
            grid-template-columns: 150px 1fr;
            row-gap: 10px;
            column-gap: 20px;
            margin-bottom: 30px;
        }
        .label {
            font-weight: 600;
            color: #555;
        }
        pre {
            background: #f4f4f4;
            padding: 20px;
            border-radius: 5px;
            font-size: 0.9em;
            overflow-x: auto;
            border: 1px solid #ddd;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>SSL Certificate Report</h1>
        <div class="info-grid">
            <div class="label">File:</div><div>$certPath</div>
            <div class="label">Subject:</div><div>$subject</div>
            <div class="label">Issuer:</div><div>$issuer</div>
            <div class="label">Expiry Date:</div><div>$expiry</div>
        </div>

        <h2>Full Certificate Output</h2>
        <pre>$certInfo</pre>
    </div>
</body>
</html>
"@

# Logs report and saves to desktop, automatically opens report in browser
$reportPath = Join-Path ([Environment]::GetFolderPath('Desktop')) "SSL-Certificate-Report.html"
$htmlReport | Out-File -FilePath $reportPath -Encoding UTF8 -Force
Write-Host "`n✅ HTML report saved to: $reportPath"
Start-Process $reportPath
