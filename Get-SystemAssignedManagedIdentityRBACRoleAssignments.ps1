$resourceGroupName = "your-resource-group-name"
$functionAppName = "your-function-app-name"
$subscriptionId = (Get-AzContext).Subscription.Id

$scope = "/subscriptions/$subscriptionId/resourceGroups/$resourceGroupName/providers/Microsoft.Web/sites/$functionAppName"

$managedIdentity = Get-AzSystemAssignedIdentity -Scope $scope

if ($managedIdentity -eq $null) {
    Write-Host "System Assigned Managed Identity not found." -ForegroundColor Red
    return
}

$managedIdentityId = $managedIdentity.PrincipalId  # Get the Principal ID of the system-assigned identity

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
