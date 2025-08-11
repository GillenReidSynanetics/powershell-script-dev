<#
.SYNOPSIS
    This script performs various cleanup operations on a Windows system. salvaged and refactored from my previous job.

.DESCRIPTION
    The script performs the following cleanup tasks:
    - Cleans the Recycle Bin.
    - Cleans the Windows Temp folder.
    - Cleans the Software Distribution Download folder.
    - Cleans the Windows Error Reporting ReportQueue.
    - Cleans user-specific folders including temporary internet files, browser caches, and other temporary data.

.PARAMETERS
    None.

.NOTES
    - The script skips cleaning Exchange logs.
    - The script uses the -Recurse, -Force, and -ErrorAction SilentlyContinue parameters to ensure thorough cleanup and to suppress errors.

.EXAMPLE
    .\Clean-Up-Script-V2.ps1
    Runs the cleanup script to remove unnecessary files and free up disk space.

#>
# --- Additional Cleanup Steps ---

# Skip Exchange logs cleanup

# Clean Recycle Bin
Remove-Item -Path "C:\$Recycle.Bin\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clean Windows Temp folder
Remove-Item -Path "C:\windows\temp\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clean Software Distribution Download folder
Remove-Item -Path "C:\Windows\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clean Windows Error Reporting ReportQueue
Remove-Item -Path "C:\ProgramData\Microsoft\Windows\WER\ReportQueue\*" -Recurse -Force -ErrorAction SilentlyContinue

# Clean user-specific folders
$foldersToClean = @(
    "Recent",
    "Cookies",
    "AppData\Local\Temp",
    "Local Settings\Temporary Internet Files",
    "AppData\Microsoft\Windows\INetCache",
    "AppData\Local\Microsoft\Windows\Temporary Internet Files\Low",
    "AppData\Local\Microsoft\Internet Explorer\CacheStorage",
    "AppData\Local\Microsoft\Internet Explorer\imagestore",
    "AppData\Local\MicrosoftEdge\User\Default",
    "AppData\Local\Google\Chrome\User Data\Default\Cache"
)

$firefoxFoldersToClean = @(
    "cache2\entries",
    "cache2\doomed",
    "jumpListCache",
    "OfflineCache",
    "thumbnails"
)

Get-ChildItem -Path "$env:SystemDrive\Users" -Directory | ForEach-Object {
    $userProfile = $_.FullName
    foreach ($folder in $foldersToClean) {
        $path = Join-Path -Path $userProfile -ChildPath $folder
        if (Test-Path -Path $path) {
            Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }

    $firefoxProfilePath = Join-Path -Path $userProfile -ChildPath "AppData\Local\Mozilla\Firefox\Profiles"
    if (Test-Path -Path $firefoxProfilePath) {
        Get-ChildItem -Path $firefoxProfilePath -Directory | ForEach-Object {
            $firefoxProfile = $_.FullName
            foreach ($folder in $firefoxFoldersToClean) {
                $path = Join-Path -Path $firefoxProfile -ChildPath $folder
                if (Test-Path -Path $path) {
                    Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}
