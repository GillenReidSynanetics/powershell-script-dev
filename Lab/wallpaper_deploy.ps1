# 
# This script is used to deploy a wallpaper system-wide for all managed machines via Intune.
# 
# The script performs the following actions:
# 1. Defines registry key paths and values for the wallpaper settings.
# 2. Specifies the URL of the image stored in Azure Blob Storage and the local directory path where the image will be saved.
# 3. Checks if the specified local directory exists; if not, it creates the directory.
# 4. Downloads the wallpaper image from the specified URL to the local directory.
# 5. Checks if the registry key path exists; if not, it creates the registry key path.
# 6. Sets the registry values for the wallpaper image path, status, and URL.
# 7. Updates the system parameters to apply the new wallpaper.
# 
# Note:
# - Ensure the image file name remains consistent to avoid issues with deployment.
# - Backup and overwrite the image in the Azure Blob Storage location as needed.

$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"


$DesktopPath = "DesktopImagePath"
$DesktopStatus = "DesktopImageStatus"
$DesktopUrl = "DesktopImageUrl"

$StatusValue = "1"


$url = "[Location that its stored on the blob storage]"
$DesktopImageValue = "[Actual Image location goes here]"
$directory = "[Directory that the image is in on local machine]"


If ((Test-Path -Path $directory) -eq $false)
{
	New-Item -Path $directory -ItemType directory
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $DesktopImageValue)



if (!(Test-Path $RegKeyPath))
{
	Write-Host "Creating registry path $($RegKeyPath)."
	New-Item -Path $RegKeyPath -Force | Out-Null
}


New-ItemProperty -Path $RegKeyPath -Name $DesktopStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $DesktopPath -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $DesktopUrl -Value $DesktopImageValue -PropertyType STRING -Force | Out-Null

RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True
