$servicePrincipalName = "your-service-principal-name-or-app-id"
$subscriptionId = (Get-AzContext).Subscription.Id

$servicePrincipal = Get-AzADServicePrincipal -DisplayName $servicePrincipalName
$servicePrincipalId = $servicePrincipal.Id

$armtoken = (Get-AzAccessToken -ResourceTypeName Arm).Token
$apiVersion = '2022-04-01'

$uri = "https://management.azure.com/subscriptions/$subscriptionId/providers/Microsoft.Authorization/roleAssignments?api-version=$apiVersion&`$filter=assignedTo('$servicePrincipalId')"

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
