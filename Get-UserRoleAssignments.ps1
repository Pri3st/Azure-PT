# Script to get all Role Assignments for a User, both Direct and Indirect (via Group membership).
# Roles assigned due to Nested Group membership are also displayed.
# The script will throw errors when enumerating for Group membership if there are no nested membership. Do not take them into consideration.
$user = Get-MgUser -UserId $userUPN
$userId = $user.Id

function Get-AllGroups {
    param (
        [string]$principalId
    )

    $groupMemberships = @()
    
    try {
        $directGroups = Get-MgUserMemberOf -UserId $principalId | Where-Object { $_.AdditionalProperties['@odata.type'] -eq '#microsoft.graph.group' }
    
        foreach ($group in $directGroups) {
            if ($group) {
                $groupMemberships += $group

                # Recursive call to find groups the current group is a member of (nested groups)
                $nestedGroups = Get-AllGroups -principalId $group.Id
                $groupMemberships += $nestedGroups
            } else {
                Write-Warning "Group ID '$($group.Id)' could not be found or has been deleted."
            }
        }
    } catch {
        Write-Warning "Failed to retrieve group memberships for Principal ID: $principalId. Error: $_"
    }
    
    return $groupMemberships
}

$directRoles = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$userId'"
$allRoles = @()

foreach ($role in $directRoles) {
    try {
        $roleDefinitionId = $role.RoleDefinitionId
        $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $roleDefinitionId

        $allRoles += [PSCustomObject]@{
            DisplayName  = $roleDefinition.DisplayName
            Description  = $roleDefinition.Description
        }
    } catch {
        Write-Warning "Failed to retrieve role definition for RoleDefinitionId: $($role.RoleDefinitionId)"
    }
}

$groups = Get-AllGroups -principalId $userId

foreach ($group in $groups) {
    $groupId = $group.Id

    $roleAssignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$groupId'"

    foreach ($roleAssignment in $roleAssignments) {
        try {
            $roleDefinitionId = $roleAssignment.RoleDefinitionId
            $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $roleDefinitionId

            # Add the role information to the result array
            $allRoles += [PSCustomObject]@{
                DisplayName  = $roleDefinition.DisplayName
                Description  = $roleDefinition.Description
            }
        } catch {
            Write-Warning "Failed to retrieve role definition for RoleDefinitionId: $($role.RoleDefinitionId)"
        }
    }
}

$allRoles | Sort-Object DisplayName -Unique | Format-Table -Property DisplayName, Description
