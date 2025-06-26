<#
.SYNOPSIS
    Script to automatically clear any Microsoft Exchange logs.

.DESCRIPTION
    This script sets the execution policy to RemoteSigned and then defines paths to various log directories related to Microsoft Exchange and IIS. 
    It includes a function, CleanLogfiles, which deletes log files older than a specified number of days from the target directories.

.PARAMETER days
    The number of days to retain log files. Files older than this will be deleted.

.PARAMETER IISLogPath
    The path to the IIS log files directory.

.PARAMETER ExchangeLoggingPath
    The path to the Microsoft Exchange log files directory.

.PARAMETER ETLLoggingPath
    The path to the ETL trace log files directory.

.PARAMETER ETLLoggingPath2
    The path to the second ETL trace log files directory.

.FUNCTION CleanLogfiles
    .SYNOPSIS
        Deletes log files older than a specified number of days from the target directory.
    .PARAMETER TargetFolder
        The path to the directory from which log files will be deleted.
    .DESCRIPTION
        This function checks if the target directory exists. If it does, it retrieves all log files (*.log, *.blg, *.etl, *.txt) 
        older than the specified number of days and deletes them. If the directory does not exist, it outputs a message indicating so.

.EXAMPLE
    Set-Executionpolicy RemoteSigned
    $days=0
    $IISLogPath="C:\inetpub\logs\LogFiles\"
    $ExchangeLoggingPath="C:\Program Files\Microsoft\Exchange Server\V15\Logging\"
    $ETLLoggingPath="C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\ETLTraces\"
    $ETLLoggingPath2="C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs"
    CleanLogfiles($IISLogPath)
    CleanLogfiles($ExchangeLoggingPath)
    CleanLogfiles($ETLLoggingPath)
    CleanLogfiles($ETLLoggingPath2)


#>
# Script to automatically clear any microsoft exchange logs.


Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force
$days=0
$IISLogPath="C:\inetpub\logs\LogFiles\"
$ExchangeLoggingPath="C:\Program Files\Microsoft\Exchange Server\V15\Logging\"
$ETLLoggingPath="C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\ETLTraces\"
$ETLLoggingPath2="C:\Program Files\Microsoft\Exchange Server\V15\Bin\Search\Ceres\Diagnostics\Logs"
Function CleanLogfiles($TargetFolder)
{
    if (Test-Path $TargetFolder) {
        $Now = Get-Date
        $LastWrite = $Now.AddDays(-$days)
        $Files = Get-ChildItem $TargetFolder -Include *.log,*.blg, *.etl, *.txt -Recurse | Where {$_.LastWriteTime -le "$LastWrite"}
        foreach ($File in $Files)
            {Write-Host "Deleting file $File" -ForegroundColor "white"; Remove-Item $File -ErrorAction SilentlyContinue | out-null}
       }
Else {
    Write-Host "The folder $TargetFolder doesn't exist! Check the folder path!" -ForegroundColor "white"
    }
}
CleanLogfiles($IISLogPath)
CleanLogfiles($ExchangeLoggingPath)
CleanLogfiles($ETLLoggingPath)
CleanLogfiles($ETLLoggingPath2)