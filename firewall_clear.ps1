
function Clear-RegistryKeys {
    try {
        # Remove and recreate Notifications key
        Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Notifications" -Recurse -ErrorAction Stop
        New-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Notifications" -ErrorAction Stop
        Write-Output "Successfully cleaned Notifications registry key."

        # Remove and recreate FirewallRules key
        Remove-Item "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\AppIso\FirewallRules" -Recurse -ErrorAction Stop
        New-Item "HKLM:\System\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\RestrictedServices\AppIso\FirewallRules" -ErrorAction Stop
        Write-Output "Successfully cleaned FirewallRules registry key."

    } catch {
        Write-Output "Error occurred: $_"
    }
}

# Check if any users are logged in
function Test-UsersLoggedIn {
    $users = query user
    if ($users) {
        Write-Output "There are users logged in. Exiting script."
        exit 1
    } else {
        Write-Output "No users logged in. Proceeding with registry cleanup."
    }
}

# Main script execution
Test-UsersLoggedIn
Clear-RegistryKeys