# This PowerShell script performs cleanup operations on various system directories and user profiles - salvaged and refactored from my previous job.
# It deletes files from the following locations:
# 
# 1. Recycle Bin
#    - C:\$Recycle.Bin\
# 
# 2. Windows Temp Directory
#    - C:\windows\temp\
# 
# 3. Windows Update Download Cache
#    - C:\Windows\SoftwareDistribution\Download
# 
# 4. Windows Error Reporting Queue
#    - C:\ProgramData\Microsoft\Windows\WER\ReportQueue
# 
# 5. User Profile Directories
#    - For each user profile in $env:SystemDrive\Users\*:
#      - Recent files
#      - Cookies
#      - Local Temp files
#      - Temporary Internet Files (Windows XP-7)
#      - Temporary Internet Files (Windows 8-10)
#      - Internet Explorer Cache Storage
#      - Internet Explorer Image Storage
#      - Microsoft Edge Cache
#      - Google Chrome Cache
#      - Mozilla Firefox Cache

$pathsToClean = @(
	"C:\$Recycle.Bin\*",
	"C:\windows\temp\*",
	"C:\Windows\SoftwareDistribution\Download\*",
	"C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*"
)

foreach ($path in $pathsToClean) {
	Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
}

$profiles = Get-ChildItem "$env:SystemDrive\Users"

foreach ($profile in $profiles) {
	$profilePath = $profile.FullName

	$userPathsToClean = @(
		"$profilePath\Recent\*",
		"$profilePath\Cookies\*",
		"$profilePath\AppData\Local\Temp\*",
		"$profilePath\Local Settings\Temporary Internet Files\*",
		"$profilePath\AppData\Microsoft\Windows\INetCache\*",
		"$profilePath\AppData\Local\Microsoft\Windows\Temporary Internet Files\Low\*",
		"$profilePath\AppData\Local\Microsoft\Internet Explorer\CacheStorage\*",
		"$profilePath\AppData\Local\Microsoft\Internet Explorer\imagestore\*",
		"$profilePath\AppData\Local\MicrosoftEdge\User\Default\*",
		"$profilePath\AppData\Local\Google\Chrome\User Data\Default\Cache\*"
	)

	foreach ($userPath in $userPathsToClean) {
		Remove-Item -Path $userPath -Recurse -Force -ErrorAction SilentlyContinue
	}

	$firefoxProfilesPath = "$profilePath\AppData\Local\Mozilla\Firefox\Profiles"
	if (Test-Path $firefoxProfilesPath) {
		$firefoxProfiles = Get-ChildItem $firefoxProfilesPath
		foreach ($firefoxProfile in $firefoxProfiles) {
			$firefoxProfilePath = $firefoxProfile.FullName
			$firefoxPathsToClean = @(
				"$firefoxProfilePath\cache2\entries\*",
				"$firefoxProfilePath\cache2\doomed\*",
				"$firefoxProfilePath\jumpListCache\*",
				"$firefoxProfilePath\OfflineCache\*",
				"$firefoxProfilePath\thumbnails\*"
			)
			foreach ($firefoxPath in $firefoxPathsToClean) {
				Remove-Item -Path $firefoxPath -Recurse -Force -ErrorAction SilentlyContinue
			}
		}
	}
}
