<#
.SYNOPSIS
    Retrieves and processes members of a specified Active Directory group and displays their last logon dates.

.DESCRIPTION
    This script prompts the user to enter the name of an Active Directory group. It then retrieves the members of the specified group and fetches their last logon dates. The results are sorted in descending order by the last logon date. Additionally, the script retrieves and displays the default domain password policy settings.

.PARAMETER groupName1
    The name of the Active Directory group whose members' last logon dates are to be retrieved.

.INPUTS
    None. The script prompts the user for input.

.OUTPUTS
    System.Object
    A list of group members with their names and last logon dates, sorted in descending order by last logon date.
    The default domain password policy settings.

.NOTES
    Requires the Active Directory module.

.EXAMPLE
    PS C:\> .\groupname.ps1
    Enter the Active Directory group name: ExampleGroup
    This will display the members of 'ExampleGroup' with their last logon dates, sorted in descending order, and the default domain password policy settings.
#>

$groupName = Read-Host -Prompt "Enter the Active Directory group name"

# Retrieve and process the members of the specified group
Get-ADGroupMember -Identity $groupName | ForEach-Object { 
    Get-ADUser -Identity $_.SamAccountName -Properties LastLogonDate | 
    Select-Object Name, LastLogonDate 
} | Sort-Object LastLogonDate -Descending

Get-ADGroupMember -Identity "$groupname" | ForEach-Object { Get-ADUser -Identity $_.SamAccountName -Properties LastLogonDate | Select-Object Name, LastLogonDate } | Sort-Object LastLogonDate -Descending


(Get-ADDefaultDomainPasswordPolicy).ComplexityEnabled
(Get-ADDefaultDomainPasswordPolicy).MinPasswordLength
(Get-ADDefaultDomainPasswordPolicy).PasswordHistoryCount
(Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge
(Get-ADDefaultDomainPasswordPolicy).LockoutDuration

