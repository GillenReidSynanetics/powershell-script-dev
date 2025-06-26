# Synanetics Tooling Deployment Script
# This script is designed to deploy the necessary features and modules for Synanetics
# It is intended to be run on a Windows system with administrative privileges
# Flexible as can add and remove features and modules as needed via $feature array and $modules array

# "Az"                    # Full Azure management (Az.Accounts, Az.Compute, etc.)
# "AWS.Tools.Installer"  # AWS PowerShell tools (use to install AWS.Tools modules)
# "GoogleCloud"          # Google Cloud SDK PowerShell integration
# "PSDocker"             # Manage Docker containers via PowerShell
# "Posh-SSH"             # SSH/SFTP support via PowerShell
# "PSScriptAnalyzer"     # Script linting and formatting rules
# "Pester"               # Unit testing framework for PowerShell scripts
# "PowerShellGet"        # Manage PowerShell module repositories
# "PackageManagement"    # Manage software packages (like Chocolatey)
# "Carbon"               # Configuration and security management
# "dbatools"             # SQL Server automation and support
# "PSWindowsUpdate"      # Manage Windows Updates remotely
# "BurntToast"           # Create custom toast notifications (for alerts/UI feedback)
# "ImportExcel"          # Work with Excel spreadsheets without needing Excel installed
# "oh-my-posh"           # Beautiful PowerShell prompt themes (great for WSL/terminal work)
# "PSReadLine"           # Enhanced command line editing and history


Write-Host "Deploying Synanetics Features" -ForegroundColor Green

$feature = @(
    "Telnet-Client"
    "OpenSSH.Client" # add whatever features you need here
)

foreach ($feature in $features) {
    try {
        write-host "Deploying $feature"
        Add-WindowsCapability -Online -Name $feature -ErrorAction Stop
    } catch {
        write-host "Failed to deploy $feature"
        write-host $_.Exception.Message
    }
}

Set-PSResourceRepository -Name PSGallery -Trusted

Write-Host "Deploying Powershell Modules" -ForegroundColor Blue
$modules = @(
    "Posh-SSH"

)

foreach ($module in $modules) {
    try {
        Write-Host "Installing module: $module"
        Install-Module -Name $module -Force -ErrorAction Stop
    } catch {
        Write-Warning "Failed to install $module. It may already be installed or not applicable to this system."
    }
}
