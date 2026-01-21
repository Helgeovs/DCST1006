function CreateUser {
    param (
        [string]$firstname,
        [string]$lastname,
        [string]$middlename,
        [string]$department,
        [string]$title,
        [string]$office
    )
    try {
        if (-not(Get-ADUser -Filter "Name -eq $firstname $lastname")) {
            Write-Host -ForegroundColor Cyan "Creating user: $firstname $lastname"
            New-ADUser -
        }
    }
    catch {
        <#Do this if a terminating exception happens#>
    }
}