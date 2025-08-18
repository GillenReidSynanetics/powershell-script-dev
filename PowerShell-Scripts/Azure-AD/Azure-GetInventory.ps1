<#
.SYNOPSIS
    This script logs into Azure, retrieves all subscriptions, resource groups, and resources, and then logs out.

.DESCRIPTION
    The script performs the following actions:
    1. Logs into Azure using device code authentication.
    2. Retrieves all Azure subscriptions associated with the logged-in account.
    3. Iterates through each subscription and sets the context to the current subscription.
    4. Retrieves all resource groups within the current subscription.
    5. Iterates through each resource group and retrieves all resources within the resource group.
    6. Outputs the name and type of each resource.
    7. Logs out from Azure.

.PARAMETER TenantId
    The tenant ID used for Azure login.

.NOTES
    - Requires the Az PowerShell module.
    - Ensure you have the necessary permissions to access the subscriptions and resources.

.EXAMPLE
    ./inventory.ps1
    This example runs the script and outputs the subscriptions, resource groups, and resources.

#>
# Login to Azure
Connect-AzAccount -TenantId '' -DeviceCode


# Get all subscriptions
$subscriptions = Get-AzSubscription

foreach ($subscription in $subscriptions) {
    Write-Output "Subscription: $($subscription.Name)"
    Set-AzContext -SubscriptionId $subscription.Id

    # Get all resource groups
    $resourceGroups = Get-AzResourceGroup
    foreach ($resourceGroup in $resourceGroups) {
        Write-Output "  Resource Group: $($resourceGroup.ResourceGroupName)"

        # Get all resources in the resource group
        $resources = Get-AzResource -ResourceGroupName $resourceGroup.ResourceGroupName
        foreach ($resource in $resources) {
            Write-Output "    Resource: $($resource.Name) - Type: $($resource.Type)"
        }
    }
}

# Logout from Azure
Disconnect-AzAccount