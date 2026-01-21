
function AddUserToGroup {
    param (
        [Parameter(Mandatory)]
        [string]$department,
        [Parameter(Mandatory)]
        [string]$groupName
    )

    # Get all users from the department
    $departmentUsers = Get-ADUser -Filter {department -eq $department} -Properties department

    # Add users to the group
    foreach ($user in $departmentUsers) {
        try {
            Add-ADGroupMember -Identity $groupName -Members $user.SamAccountName
            Write-Host "Added $($user.Name) to $groupName"
        }
        catch {
            Write-Host "Error adding $($user.Name): $_"
        }
    }
}
