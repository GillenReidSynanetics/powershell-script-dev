<#
.SYNOPSIS
    Connects to Azure Graph and retrieves all device management scripts in an Azure environment.

.DESCRIPTION
    This script connects to the Azure Graph API and retrieves all device management scripts available in the specified Azure environment.
    The scripts are then saved to a specified local directory.

.NOTES
    This script has not been tested for Synanetics.

.PARAMETER Path
    The local directory where the scripts will be saved. Default is "C:\temp".

.EXAMPLE
    .\devicemanagement-scripts.ps1
    Connects to Azure Graph, retrieves all device management scripts, and saves them to the default directory "C:\temp".

.EXAMPLE
    .\devicemanagement-scripts.ps1 -Path "D:\Scripts"
    Connects to Azure Graph, retrieves all device management scripts, and saves them to the specified directory "D:\Scripts".

#>
# Script will connect to azure graph and grab a copy of all device management scripts in an azure enviroment

## Not tested for synanetics ##

Install-Module NuGet
Install-Module -Name Microsoft.Graph.Intune
Import-Module Microsoft.Graph.Intune -Global
 
#The path where the scripts will be saved
$Path = "C:\temp"
 
#The connection to Azure Graph
Connect-MSGraph 
 
#Get Graph scripts
$ScriptsData = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts" -HttpMethod GET
 
$ScriptsInfos = $ScriptsData.value | select id,fileName,displayname
$NBScripts = ($ScriptsInfos).count
 
if ($NBScripts -gt 0){
    Write-Host "Found $NBScripts scripts :" -ForegroundColor Yellow
    $ScriptsInfos | FT DisplayName,filename
    Write-Host "Downloading Scripts..." -ForegroundColor Yellow
    foreach($ScriptInfo in $ScriptsInfos){
        #Get the script
        $script = Invoke-MSGraphRequest -Url "https://graph.microsoft.com/beta/deviceManagement/deviceManagementScripts/$($scriptInfo.id)" -HttpMethod GET
        #Save the script
        [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($($script.scriptContent))) | Out-File -FilePath $(Join-Path $Path $($script.fileName))  -Encoding ASCII 
    }
    Write-Host "All scripts downloaded!" -ForegroundColor Yellow        
}