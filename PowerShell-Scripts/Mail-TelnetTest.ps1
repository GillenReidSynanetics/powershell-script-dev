<#
.SYNOPSIS
    Sends a test email using the specified SMTP server and port via PowerShell.

.DESCRIPTION
    This script prompts the user for SMTP server details, sender and recipient email addresses, and the SMTP port.
    It then attempts to send a test email using the Send-MailMessage cmdlet.
    The script provides feedback on the success or failure of the email delivery.

.PARAMETER smtpServer
    The address of the SMTP server to use for sending the email (e.g., smtp.example.com).

.PARAMETER fromEmail
    The sender's email address (e.g., sender@example.com).

.PARAMETER toEmail
    The recipient's email address (e.g., recipient@example.com).

.PARAMETER port
    The port number to use for the SMTP server (e.g., 587 or 25).

.EXAMPLE
    PS> .\telnet.ps1
    Prompts for SMTP server, sender, recipient, and port, then sends a test email.

.NOTES
    - Ensure that the SMTP server allows relay from your IP address.
    - The Send-MailMessage cmdlet may be deprecated in future PowerShell versions.
    - Authentication is not handled in this script; for authenticated SMTP servers, additional parameters are required.
#>

Write-Host "This tool will send a test email using Telnet. " -ForegroundColor Yellow

$smtpServer = Read-Host "Enter the SMTP Server address (e.g., smtp.example.com)"
$fromEmail = Read-Host "Enter the sender's email address (e.g., sender@example.com)"
$toEmail = Read-Host "Enter the recipient's email address (e.g., recipient@example.com)"
$port = Read-Host "Enter the SMTP port (e.g., 587 or 25)"


$mailParams = @{
    SmtpServer = $smtpServer
    Port       = $port
    From       = $fromEmail
    To         = $toEmail
    Subject    = "Test Email from PowerShell - $(Get-Date)"
    Body       = "This is a test email sent using the modern Send-MailMessage cmdlet."
}


Write-Host "Attempting to send mail using $smtpServer on port $port..." -ForegroundColor Cyan

try {
    Send-MailMessage @mailParams -ErrorAction Stop
    Write-Host "Email sent successfully!" -ForegroundColor Green
}
catch {
    Write-Error "Failed to send email. Please check your SMTP server settings and try again. Error: $($_.Exception.Message)"
    exit 1
}