$results = Invoke-ScriptAnalyzer -Path "C:\Users\GillenReid\Documents\Repos\Script-Lab\powershell-script-dev\Lab" -Recurse

$outdatedPracticeRules = @(
    'PSAvoidUsingWMICmdlet',      # Flags the old 'Get-WmiObject'
    'PSAvoidUsingWriteHost',      # Flags using Write-Host instead of proper output
    'PSAvoidUsingCmdletAliases',  # Flags aliases like 'ls', 'dir', 'gci'
    'PSUseCmdletCorrectly'        # Flags issues with deprecated parameters
)

$results | Where-Object { $_.RuleName -in $outdatedPracticeRules } | ForEach-Object {
    Write-Host "Outdated practice found in $($_.Path): $($_.Message)"
}