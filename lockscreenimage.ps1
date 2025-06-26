<#
.SYNOPSIS
	This script sets the lock screen image on a Windows machine by downloading an image from a specified URL and updating the registry.

.DESCRIPTION
	The script performs the following actions:
	1. Defines the registry key path for the lock screen image settings.
	2. Specifies the lock screen image path, status, and URL.
	3. Downloads the lock screen image from a given URL to a specified local directory.
	4. Creates the local directory if it does not exist.
	5. Creates the registry key path if it does not exist.
	6. Sets the lock screen image path, status, and URL in the registry.
	7. Updates the system parameters to apply the new lock screen image.

.PARAMETER RegKeyPath
	The registry key path where the lock screen image settings are stored.

.PARAMETER LockScreenPath
	The registry value name for the lock screen image path.

.PARAMETER LockScreenStatus
	The registry value name for the lock screen image status.

.PARAMETER LockScreenUrl
	The registry value name for the lock screen image URL.

.PARAMETER StatusValue
	The value indicating the status of the lock screen image.

.PARAMETER url
	The URL of the cloud-stored image to be used as the lock screen image.

.PARAMETER LockScreenImageValue
	The local path where the downloaded lock screen image will be saved.

.PARAMETER directory
	The local directory where the lock screen image will be saved.

.NOTES
	This script is not tested and uses the registry to confirm the lock screen image.

.EXAMPLE
	.\lockscreenimage.ps1
	This command runs the script to set the lock screen image on the local machine.
#>

# Not a tested script - uses the registry as a way to confirm lockscreen image

???$RegKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"


$LockScreenPath = "LockScreenImagePath"
$LockScreenStatus = "LockScreenImageStatus"
$LockScreenUrl = "LockScreenImageUrl"

$StatusValue = "1"


$url = "{URL-Cloud-Stored-Image}"
$LockScreenImageValue = "Local-Location-Of-IMG"
$directory = "C:\Directory-Its-In"


If ((Test-Path -Path $directory) -eq $false)
{
	New-Item -Path $directory -ItemType directory
}

$wc = New-Object System.Net.WebClient
$wc.DownloadFile($url, $LockScreenImageValue)



if (!(Test-Path $RegKeyPath))
{
	Write-Host "Creating registry path $($RegKeyPath)."
	New-Item -Path $RegKeyPath -Force | Out-Null
}


New-ItemProperty -Path $RegKeyPath -Name $LockScreenStatus -Value $StatusValue -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $LockScreenPath -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $LockScreenUrl -Value $LockScreenImageValue -PropertyType STRING -Force | Out-Null

RUNDLL32.EXE USER32.DLL, UpdatePerUserSystemParameters 1, True
