<#
.SYNOPSIS
Generates a change request template for SSL certificate replacement in a specified service environment.

.DESCRIPTION
This script prompts the user for details such as Change Request ID, ODS Code (service name), type of SSL being replaced, and the environment. It then generates a pre-formatted change request template containing sections for description, implementation plan, backout plan, and test plan. The template is saved as a text file named after the Change Request ID in the script's directory.

.PARAMETER changeID
The Change Request ID associated with this SSL replacement.

.PARAMETER serviceName
The ODS Code or name of the service for which the SSL certificate is being replaced.

.PARAMETER sslFrom
Specifies which SSL certificate(s) are being replaced: Server, Client, Signing, or All 3.

.PARAMETER environment
The environment where the change will be implemented (e.g., Production, Staging).

.OUTPUTS
A text file containing the change request template, saved in the script's directory.

.EXAMPLE
PS> .\ssl-replacement-gen-dev.ps1
# Prompts for required information and generates a change request template file.

.NOTES
- This script is intended as a template generator; all sections should be reviewed and edited before submitting the change request.
- Ensure you have the necessary permissions to run this script and write to the output directory.
#>

$changeID = Read-Host "Enter the Change Request ID"
$serviceName = Read-Host "Enter ODS Code"
$sslFrom = Read-Host "What SSL are you replacing Server/Client/Signing or All 3?"
$environment = Read-Host "Enter the environment (e.g., Production, Staging)"
Write-Host "`This is a template only. Ensure all sections are reviewed and edited before submitting your change request!" -ForegroundColor Yellow
Start-Sleep -Seconds 2
$outputFile = Join-Path $PSScriptRoot "$changeID.txt"
$template = @"


==============================
🔹 DESCRIPTION
==============================
This change involves renewing $sslFrom certificates for the $serviceName service in the $environment environment. The change is necessary to ensure continued secure communication and compliance with security standards.

SSD ticket associated with this change: 

==============================
🔹 IMPLEMENTATION PLAN
==============================
1. Remote onto the server where the (Url to Client Remote Access here) service is hosted. 
2. Navigate to the directory where the service is located - in this case $environment.
   Example: C:\Program Files\Docker\compose\${serviceName}\${environment}
   Note: Ensure you have the correct path to the service directory.
3. Start up PowerShell in administrator - run the command "Docker PS" to check current environment status and identify container status.
4. Login to onboarding portal - access $serviceName provider and ensure environment set is $environment - Ensure you check passphrases are used or not used in the .env file.
5. Run the script called CertBackupAndValidate.ps1 which will backup the current SSL certificates and validate them via reading the .env file.
6. Replace the SSL certificates with the new ones provided by the service provider.
   - Ensure the new certificates are in the correct format and location as required by the service.
7. Observer for a startup.bat file in the service directory - file will contain the necessary commands to apply the new SSL certificates.
   - If it exists, run the startup.bat file to apply the new SSL certificates.
   - If it does not exist, manually restart the service to apply the changes.
8. After the service has restarted, run the command "Docker PS" again to check the status of the service.

==============================
🔹 BACKOUT PLAN
==============================
1. Extract the backup of the SSL certificates from the CertBackupAndValidate.ps1 script.
2. Overwrite the implemented SSL certificates with the backed-up versions and the .env file.
3. Restart the service to revert to the previous SSL certificates.

==============================
🔹 TEST PLAN
==============================
1. Verify that the new SSL certificates are correctly installed and recognized by the service.
2. Test the service functionality to ensure it operates as expected with the new SSL certificates.
3. Docker Logs -f <container_name> to monitor the service logs for any errors or issues.

"@

$template | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Change request template generated at: $outputFile" -ForegroundColor Green
Read-Host "Press Enter to exit"
exit