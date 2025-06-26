# Upgrade Generator Script
# This script generates a change request template for upgrading a service version.

# Variables from users input
# Prompt the user for input
$changeID = Read-Host "Enter the CR ID"
$enviroment = Read-Host "Enter Environment (e.g., Production, Staging)"
$serviceName = Read-Host "Enter ODS Code"
$versionFrom = Read-Host "Enter Current Version"
$versionTo = Read-Host "Enter New Version"


# Notification to ensure the user reviews the template - this is a template only
Write-Host "`WARNING: This is a template only. Ensure all sections are reviewed and edited before submitting your change request!" -ForegroundColor Yellow
Start-Sleep -Seconds 2

# Drops CR ID into the filename and generates the output file path
$outputFile = Join-Path $PSScriptRoot "$changeID.txt"

# Template text with placeholders for user input
$template = @"
============================== 
DESCRIPTION 
============================== 

This change involves updating the $enviroment from version $versionFrom to version $versionTo. The upgrade is part of the scheduled platform maintenance window on . This update includes performance enhancements and minor bug fixes. 

============================== 
IMPLEMENTATION PLAN 
============================== 

0.1. Check the customer has database backups in place and restoration is a viable option for backout should there be issues on upgrade. 
1. RDP into the server hosting the $serviceName service. - ( Add Text Here ) 
1. a. Run docker commands ( Docker Logs fhir-appliance --tail 200 ) against the fhir-appliance instance to extract current logs to text file. 
1. b. Perform current log analysis to highlight any current exceptions on the latest version 
2. Navigate the pathway to the service directory <directory> (Add Path Here). 
   - Example: C:\FHIR-Appliance 
3. Create a folder CR-$changeID and copy and pasted the .env and docker-compose.yml files to ensure provisions are in place for rollback if needed. 
4. Review https://hub.docker.com/r/synaneticsltd/synfhir-store/tags to identify the $versionTo image tag. 
5. Note the existing version using https://synanetics.atlassian.net/wiki/spaces/SYNS/pages/2909929589/FHIR+Appliance+Support 
6. Open the docker-compose.yml using notepad ++ in admin mode - identify the service. 
7. Update the image tag to $versionTo in the docker-compose.yml file. 
8. Standard procedure is to have a local batch file called startup.bat - this file should contain all the commands to restart the service. 
8.1 The batch file is called startup.bat and is located in the local directory of the service. 
9. Once these commands are run* what commands?, you will see the docker engine pull the new image and restart the service. 
10. Run the command docker ps to monitor the status of the service - ensure containers are running and healthy. 
11. Run the command docker logs -f Test fhir-appliance to monitor the logs for any errors or warnings. 
11.1 repeat steps 1a and 1b so log file outputs can be compared before and after the change. 

============================== 
BACKOUT PLAN 
============================== 

1. Go into backup directory (Step 3) and restore the previous versions of the .env and docker-compose.yml files and overwrite the current versions. 
2. Revert the image tag in the docker-compose.yml file to $versionFrom. 
3. See step 8 above for the startup.bat file. 
*In the event of an emergency, database backup should be restored.  

============================== 
TEST PLAN 
============================== 
- Validate the successful deployment of $versionTo. 
- Confirm $versionTo endpoints respond as expected. 
- Verify application logs for errors, any indications of any query issue, performance degradation or any further errors during container startup and stabilisation.
- Confirm the service is running and healthy.
- Confirm the service is accessible via the expected endpoints.
- Confirm the service is functioning as expected with no errors or performance issues.  
"@

# Output the template to the specified file
$template | Out-File -FilePath $outputFile -Encoding UTF8
Write-Host "Change request template generated at: $outputFile" -ForegroundColor Green
Read-Host "Press Enter to exit"
exit