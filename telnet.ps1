<#
.SYNOPSIS
    Tests functionality of an SMTP server using Telnet via PowerShell.

.DESCRIPTION
    This script is used to test the functionality of an SMTP server in an environment where a virtual SMTP server is still in use via IIS. 
    It enables the Telnet client, connects to the specified SMTP server, and sends a test email.

.PARAMETER smtpServer
    The name of the local SMTP server.

.PARAMETER smtpPort
    The port number of the SMTP server. Default is 587.

.PARAMETER senderEmail
    The email address of the sender.

.PARAMETER recipientEmail
    The email address of the recipient.

.PARAMETER subject
    The subject of the test email. Default is "Test Email from PowerShell".

.PARAMETER body
    The body content of the test email. Default is "This is a test email sent via PowerShell and Telnet."

.NOTES
    Ensure that the Telnet client is enabled on the system before running this script.

.EXAMPLE
    .\telnet.ps1 -smtpServer "smtp.example.com" -smtpPort 587 -senderEmail "sender@example.com" -recipientEmail "recipient@example.com"

    This example sends a test email from "sender@example.com" to "recipient@example.com" using the SMTP server "smtp.example.com" on port 587.
#>

# This script Tests functionality of an SMTP server, used in an enviroment where virtual SMTP server was still in use via IIS


# Ensure Telnet client is enabled
Enable-WindowsOptionalFeature -Online -FeatureName TelnetClient

# SMTP Server Settings
$smtpServer = "(Local-SMTPServer-Name)"
$smtpPort = 587  
$senderEmail = "(Sender-Email)"
$recipientEmail = "(Recipient-Email)"

# Email Content
$subject = "Test Email from PowerShell"
$body = "This is a test email sent via PowerShell and Telnet."

# Telnet Connection and Commands
$telnet = New-Object System.Net.Sockets.TcpClient($smtpServer, $smtpPort)
$stream = $telnet.GetStream()
$writer = New-Object System.IO.StreamWriter($stream)
$reader = New-Object System.IO.StreamReader($stream)

# Read initial greeting from server
$reader.ReadLine()

# Send SMTP commands
$writer.WriteLine("HELO $smtpServer")
$reader.ReadLine()
$writer.WriteLine("MAIL FROM: <$senderEmail>")
$reader.ReadLine()
$writer.WriteLine("RCPT TO: <$recipientEmail>")
$reader.ReadLine()
$writer.WriteLine("DATA")
$reader.ReadLine()
$writer.WriteLine("Subject: $subject")
$writer.WriteLine()
$writer.WriteLine($body)
$writer.WriteLine(".")
$reader.ReadLine()

# Close the connection
$writer.WriteLine("QUIT")
$telnet.Close()
