# Script to get all Role Assignments for a Managed Identity, both Direct and Indirect (via Group membership).
# Roles assigned due to Nested Group membership are also displayed.
# The script will throw errors when enumerating for non-existent nested Group membership. Do not take them into consideration, the final results will be valid.
$user = Get-MgServicePrincipal -Filter "servicePrincipalType eq 'ManagedIdentity'" | Where-Object {$_.DisplayName -like "*<NAME_OF_MANAGED_IDENTITY*"}
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

function Get-RoleAssignmentsWithScope {
    param (
        [string]$principalId
    )

    $rolesWithScope = @()
    
    $roleAssignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "principalId eq '$principalId'"

    foreach ($roleAssignment in $roleAssignments) {
        try {
            $roleDefinitionId = $roleAssignment.RoleDefinitionId
            $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -UnifiedRoleDefinitionId $roleDefinitionId

            $directoryScopeId = $roleAssignment.DirectoryScopeId
            $scope = if ($directoryScopeId) { $directoryScopeId } else { 'N/A' }

            $rolesWithScope += [PSCustomObject]@{
                DisplayName  = $roleDefinition.DisplayName
                Description  = $roleDefinition.Description
                Scope        = $scope
                RoleId       = $roleDefinitionId
                AssignmentId = $roleAssignment.Id
            }
        } catch {
            Write-Warning "Failed to retrieve role definition for RoleDefinitionId: $($roleAssignment.RoleDefinitionId)"
        }
    }

    return $rolesWithScope
}

$directRoles = Get-RoleAssignmentsWithScope -principalId $userId

$groups = Get-AllGroups -principalId $userId

$allRoles = $directRoles

foreach ($group in $groups) {
    $groupId = $group.Id

    $groupRoles = Get-RoleAssignmentsWithScope -principalId $groupId
    $allRoles += $groupRoles
}

foreach ($role in $allRoles | Sort-Object DisplayName -Unique) {
    Write-Output "Role: $($role.DisplayName)"
    Write-Output "Description: $($role.Description)"
    Write-Output "Scope: $($role.Scope)"
    Write-Output "RoleId: $($role.RoleId)"
    Write-Output "AssignmentId: $($role.AssignmentId)"
    Write-Output "-----------------------------"
}
