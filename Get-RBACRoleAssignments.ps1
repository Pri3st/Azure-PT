<#
Script to find RBAC Roles assigned to a User or Service Principal based on the [Azure Resource Manager (ARM) API](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-rest)

If the user is a member of a group that has a role assignment, that role assignment is also listed. This filter is transitive for groups which means that if the user is a member of a group and that group is a member of another group that has a role assignment, that role assignment is also listed.
This filter only accepts an object ID for a user or a service principal. You cannot pass an object ID for a group.

RBAC Roles dictate the access level to Azure Resources
#>

<#
Authenticate to Azure via the `Az` Module as the User/Service Principal
$password = ConvertTo-SecureString '<PASSWORD>' -AsPlainText -Force
$creds = New-Object System.Management.Automation.PSCredential('<UPN>', $password)
Connect-AzAccount -Credential $creds
#>

# Get role assignments
$userUPN = (Get-AzContext).Account.Id
$subscriptionId = (Get-AzContext).Subscription.Id
$user = Get-AzADUser -UserPrincipalName $userUPN
$userId = $user.Id
$armtoken = (Get-AzAccessToken -ResourceTypeName Arm).Token
$apiVersion = '2022-04-01'

$uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleAssignments?api-version=$apiVersion&`$filter=assignedTo('$userId')"

$requestParams = @{
    Method  = 'GET'
    Uri     = $uri
    Headers = @{
        'Authorization' = "Bearer $armtoken"
    }
}

$response = Invoke-RestMethod @requestParams

# Get role definitions
foreach ($assignment in $response.value) {
    $roleDefinitionId = $assignment.properties.roleDefinitionId
    $roleDefinitionIdParts = $roleDefinitionId -split '/'
    $roleDefinitionIdFinal = $roleDefinitionIdParts[-1]
    
    $roleDefinition = Get-AzRoleDefinition -Id $roleDefinitionIdFinal
    $roleDefinition | Format-List *
}
