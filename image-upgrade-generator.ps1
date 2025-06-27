
<#
.SYNOPSIS
Generates a change request template for upgrading a service image version.

.DESCRIPTION
This script prompts the user for a Change Request (CR) ID, ODS Code (service name), current version, and new version. It then generates a change request template file containing sections for description, implementation plan, backout plan, and test plan. The template is intended to be reviewed and edited before submitting the change request.

.PARAMETER changeID
The Change Request ID entered by the user.

.PARAMETER serviceName
The ODS Code or service name entered by the user.

.PARAMETER versionFrom
The current version of the service image.

.PARAMETER versionTo
The new version of the service image to upgrade to.

.OUTPUTS
A text file named after the CR ID, containing the change request template.

.NOTES
- The script displays a warning to ensure the template is reviewed before submission.
- The template includes placeholders for additional details such as URLs, script names, and test details.
- The script must be run in an environment where user input is possible.

.EXAMPLE
PS> .\image-upgrade-gen-dev.ps1
# Prompts for required information and generates a change request template file.
#>
$changeID = Read-Host "Enter the CR ID"
$serviceName = Read-Host "Enter ODS Code"
$versionFrom = Read-Host "Enter Current Version"
$versionTo = Read-Host "Enter New Version"
Write-Host "`n⚠️  WARNING: This is a template only. Ensure all sections are reviewed and edited before submitting your change request!" -ForegroundColor Yellow
Start-Sleep -Seconds 2


$outputFile = Join-Path $PSScriptRoot "$changeID.txt"


$template = @"


==============================
🔹 DESCRIPTION
==============================
This change involves updating the $serviceName` from version $versionFrom to version $versionTo. The upgrade is part of the scheduled platform maintenance window on $changeWindow. This update includes performance enhancements and minor bug fixes.

==============================
🔹 IMPLEMENTATION PLAN
==============================
1. Use the following information to remote onto the enviroment in question - (Add URL Here)
2. Navigate the pathway to the service directory (Use confluence to find the path).
3. Use the (Script Name Here) to backup .env and docker-compose.yml files to ensure rollback capability.
4. Review https://hub.docker.com/r/synaneticsltd/synfhir-store/tags to identify the latest version of the `$serviceName` image.
5. Note the existing version using https://synanetics.atlassian.net/wiki/spaces/SYNS/pages/2909929589/FHIR+Appliance+Support
6. Open the docker-compose.yml using notepad ++ in admin mode - identify the $serviceName service, text should resemble (Add Text Here).
7. Update the image tag to $versionTo in the docker-compose.yml file.
8. Standard procedure is to have a local batch file called startup.bat - this file should contain all the commands to restart the service.
9. Once these commands are run, you will see the docker engine pull the new image and restart the service.
10. Run the command docker ps to monitor the status of the service - ensure containers are running and healthy.
11. Run the command docker logs -f $serviceName to monitor the logs for any errors or warnings.

==============================
🔹 BACKOUT PLAN
==============================
1. Go into backup directory and restore the previous versions of the .env and docker-compose.yml files and overwrite the current versions.
2. Revert the image tag in the docker-compose.yml file to $versionFrom.
3. See step 8 above for the startup.bat file.

==============================
🔹 TEST PLAN
==============================
- Validate the successful deployment of $versionTo.
- Confirm $serviceName endpoints respond as expected.
- Verify application logs for errors.
- Confirm $testDetails during post-deployment checks.
"@

$template | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Change request template generated at: $outputFile" -ForegroundColor Green
Read-Host "Press Enter to exit"
exit