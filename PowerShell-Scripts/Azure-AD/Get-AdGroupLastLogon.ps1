<#
.SYNOPSIS
Retrieves the last logon date for members of an Active Directory group.

.DESCRIPTION
The Get-AdGroupLastLogon function takes an Active Directory group identity as input, retrieves the group, and then lists all users who are members of that group along with their last logon date. The results are sorted by the last logon date in descending order.

.PARAMETER Identity
The identity (name, distinguished name, GUID, or SID) of the Active Directory group whose members' last logon dates are to be retrieved.

.EXAMPLE
Get-AdGroupLastLogon -Identity "HR Team"

This command retrieves the last logon dates for all members of the "HR Team" Active Directory group.

.NOTES
Requires the AzureAD and ActiveDirectory modules. Ensure you are connected to the appropriate services before running this function.

#>
# Get-AdGroupLastLogon.ps1

function Get-AdGroupLastLogon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Identity
    )
try {
    $group = get-adgroup -Identity $Identity -ErrorAction Stop

    Get-AzADUser -filter "memberof -eq '$($group.DistinguishedName)'" -Properties LastLogonDate |
    Select-Object Name, LastLogonDate |
    Sort-Object LastLogonDate -Descending 
}
catch {
    Write-Error "Failed to retrieve members for group '$Identity'. Details: $($_.Exception.Message)"
    return
}
    
}