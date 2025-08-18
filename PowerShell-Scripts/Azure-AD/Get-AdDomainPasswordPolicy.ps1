function Get-AdDomainPasswordPolicy {
    <#
    .SYNOPSIS
        Retrieves the default domain password policy settings.

    .DESCRIPTION
        The Get-AdDomainPasswordPolicy function queries the Active Directory for the default domain password policy.
        It returns key password policy attributes such as complexity requirements, minimum password length, password history count, maximum password age, and lockout duration in a single, easy-to-read object.

    .EXAMPLE
        Get-AdDomainPasswordPolicy

        Returns the current default domain password policy settings as a custom PowerShell object.

    .NOTES
        Requires the Active Directory module and appropriate permissions to query domain password policy.
        If the policy cannot be retrieved, an error message is displayed.

    .OUTPUTS
        PSCustomObject
            ComplexityEnabled    : [bool]    # Whether password complexity is required
            MinPasswordLength    : [int]     # Minimum number of characters for passwords
            PasswordHistoryCount : [int]     # Number of previous passwords remembered
            MaxPasswordAge       : [timespan]# Maximum password age before expiration
            LockoutDuration      : [timespan]# Duration of account lockout

    #>
    [CmdletBinding()]
    param()

    try {
        # Call the cmdlet only once and store the result
        $policy = Get-ADDefaultDomainPassword-Policy -ErrorAction Stop
        
        # Output the results as a single, easy-to-read object
        [PSCustomObject]@{
            ComplexityEnabled    = $policy.ComplexityEnabled
            MinPasswordLength    = $policy.MinPasswordLength
            PasswordHistoryCount = $policy.PasswordHistoryCount
            MaxPasswordAge       = $policy.MaxPasswordAge
            LockoutDuration      = $policy.LockoutDuration
        }
    }
    catch {
        Write-Error "Failed to retrieve the domain password policy. Details: $($_.Exception.Message)"
    }
}