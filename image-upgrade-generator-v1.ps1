# Upgrade Generator Script
# This script generates a change request template for upgrading a service version.
$changeID = Read-Host "Enter the CR ID"
$serviceName = Read-Host "Enter ODS Code"
$versionFrom = Read-Host "Enter Current Version"
$versionTo = Read-Host "Enter New Version"


# Notification to ensure the user reviews the template
Write-Host "`WARNING: This is a template only. Ensure all sections are reviewed and edited before submitting your change request!" -ForegroundColor Yellow
Start-Sleep -Seconds 2
# Drops CR ID into the filename and generates the output file path
$outputFile = Join-Path $PSScriptRoot "$changeID.txt"


# Template text with placeholders for user input
$template = @"
==============================
DESCRIPTION
==============================
This change involves updating the $serviceName from version $versionFrom to version $versionTo. The upgrade is part of the scheduled platform maintenance window on $changeWindow. This update includes performance enhancements and minor bug fixes.

==============================
IMPLEMENTATION PLAN
==============================
1. RDP into the server hosting the $serviceName service. - ( Add Text Here )
2. Navigate the pathway to the service directory (Add Path Here).
   - Example: C:\FHIR-Appliance
3. Create a folder CR-$changeID .env and docker-compose.yml files to ensure provisions are in place for rollback if needed.
4. Review https://hub.docker.com/r/synaneticsltd/synfhir-store/tags to identify the $versionTo image tag.
5. Note the existing version using https://synanetics.atlassian.net/wiki/spaces/SYNS/pages/2909929589/FHIR+Appliance+Support
6. Open the docker-compose.yml using notepad ++ in admin mode - identify the $serviceName service.
7. Update the image tag to $versionTo in the docker-compose.yml file.
8. Standard procedure is to have a local batch file called startup.bat - this file should contain all the commands to restart the service.
9. Once these commands are run, you will see the docker engine pull the new image and restart the service.
10. Run the command docker ps to monitor the status of the service - ensure containers are running and healthy.
11. Run the command docker logs -f $serviceName fhir-appliance to monitor the logs for any errors or warnings.
12. Once complete and successful, apply to relevant github configuration 

==============================
BACKOUT PLAN
==============================
1. Go into backup directory (Step 3) and restore the previous versions of the .env and docker-compose.yml files and overwrite the current versions.
2. Revert the image tag in the docker-compose.yml file to $versionFrom.
3. See step 8 above for the startup.bat file.

==============================
TEST PLAN
==============================
- Validate the successful deployment of $versionTo.
- Confirm $serviceName endpoints respond as expected.
- Verify application logs for errors.
- Confirm $testDetails during post-deployment checks.
"@

# Output the template to the specified file
$template | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Change request template generated at: $outputFile" -ForegroundColor Green
Read-Host "Press Enter to exit"
exit