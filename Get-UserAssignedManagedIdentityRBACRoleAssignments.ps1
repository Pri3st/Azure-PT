$managedIdentityName = "your-user-assigned-managed-identity-name"
$resourceGroupName = "your-resource-group-name"
$subscriptionId = (Get-AzContext).Subscription.Id

$managedIdentity = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $managedIdentityName

if ($managedIdentity -eq $null) {
    Write-Host "User Assigned Managed Identity not found." -ForegroundColor Red
    return
}

$managedIdentityId = $managedIdentity.Id  # Get the resource ID of the managed identity

$armtoken = (Get-AzAccessToken -ResourceTypeName Arm).Token
$apiVersion = '2022-04-01'

$uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleAssignments?api-version=$apiVersion&`$filter=assignedTo('$managedIdentityId')"

$requestParams = @{
    Method  = 'GET'
    Uri     = $uri
    Headers = @{
        'Authorization' = "Bearer $armtoken"
    }
}

$response = Invoke-RestMethod @requestParams

foreach ($assignment in $response.value) {
    $roleDefinitionId = $assignment.properties.roleDefinitionId
    $roleDefinitionIdParts = $roleDefinitionId -split '/'
    $roleDefinitionIdFinal = $roleDefinitionIdParts[-1]
    
    $roleDefinition = Get-AzRoleDefinition -Id $roleDefinitionIdFinal
    $roleDefinition | Format-List *
}
