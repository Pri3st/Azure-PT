# Find Role Assignments for a User
## The script finds Direct and Indirect (deriving from Group Membership) Role Assignments
$userUPN = "targetuser@domain.com"
$user = Get-MgUser -UserId $userUPN
$userId = $user.Id

$directRoles = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$userId'"
$allRoles = @()

foreach ($role in $directRoles) {
    $roleDefinitionId = $role.RoleDefinitionId
    $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $roleDefinitionId

    $allRoles += [PSCustomObject]@{
        DisplayName  = $roleDefinition.DisplayName
        Description  = $roleDefinition.Description
    }
}

$groups = Get-MgUserMemberOf -UserId $userId | Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' }

foreach ($group in $groups) {
    $groupId = $group.Id

    # Get role assignments for the current group
    $roleAssignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$groupId'"

    # For each role assignment, retrieve role definition details
    foreach ($roleAssignment in $roleAssignments) {
        $roleDefinitionId = $roleAssignment.RoleDefinitionId
        $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $roleDefinitionId

        # Add the role information to the result array
        $allRoles += [PSCustomObject]@{
            DisplayName  = $roleDefinition.DisplayName
            Description  = $roleDefinition.Description
        }
    }
}

$allRoles | Sort-Object DisplayName -Unique | Format-Table -Property DisplayName, Description
