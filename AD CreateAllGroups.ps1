$parentOU = "OU=InfraIT_Groups,DC=InfraIT,DC=sec"
$searchBase = "OU=InfraIT_Users,DC=InfraIT,DC=sec"

$userGroups = Get-ADOrganizationalUnit -Filter * -SearchBase $searchBase | Select-Object Name

function CreateGroup {
    param (
        [string]$group,
        [string]$parentOU
    )
    try {
    $groupName = "g_all_$group"
    $existingGroup = Get-ADGroup `
        -Filter "Name -eq '$groupName'" `
        -SearchBase $ParentOU

    
     if (-not($existingGroup)) {
        Write-Host -ForegroundColor Cyan "Creating: g_all_$group"
        New-ADGroup -Name "g_all_$group" -GroupScope Global -Path $parentOU -GroupCategory Security
     }   
     else {
        Write-Host -ForegroundColor Yellow "Group g_all_$group already exist."
     }
    }
    catch {
        Write-Warning "Failed to create g_all_$group : $_"
    }
}

foreach ($group in $userGroups) {
    CreateGroup -group $group.Name -parentOU $parentOU
}