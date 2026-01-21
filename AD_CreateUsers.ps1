function Test-ADUserExists {
    param(
        [Parameter(Mandatory)]
        [string]$SamAccountName
    )
    
    try {
        $user = Get-ADUser -Identity $SamAccountName
        return $true
    }
    catch [Microsoft.ActiveDirectory.Management.ADIdentityNotFoundException] {
        return $false
    }
    catch {
        Write-Error "Error checking user existence: $_"
        return $false
    }
}

function New-RandomPassword {
    # Character sets
    $lowerCase = "abcdefghijklmnopqrstuvwxyz"
    $upperCase = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    $numbers = "0123456789"
    # Safe special characters based on common practices
    $specialChars = "!@#$%^&*()-_=+[]{}|;:,.<>?"

    # Combined character set
    $allChars = $lowerCase + $upperCase + $numbers + $specialChars

    # Random password length between 13 and 17
    $passwordLength = Get-Random -Minimum 13 -Maximum 18

    # Creating an array to hold password characters
    $passwordChars = @()

    # Ensuring at least one character from each set
    $passwordChars += $lowerCase.ToCharArray()[(Get-Random -Maximum $lowerCase.Length)]
    $passwordChars += $upperCase.ToCharArray()[(Get-Random -Maximum $upperCase.Length)]
    $passwordChars += $numbers.ToCharArray()[(Get-Random -Maximum $numbers.Length)]
    $passwordChars += $specialChars.ToCharArray()[(Get-Random -Maximum $specialChars.Length)]

    # Filling the rest of the password
    for ($i = $passwordChars.Count; $i -lt $passwordLength; $i++) {
        $passwordChars += $allChars.ToCharArray()[(Get-Random -Maximum $allChars.Length)]
    }

    # Shuffle the characters to remove predictable patterns
    $password = -join ($passwordChars | Get-Random -Count $passwordChars.Count)

    # Convert to SecureString
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force

    return $securePassword
}

function New-StandardUsername {
    param(
        [Parameter(Mandatory)]
        [string]$GivenName,
        [string]$MiddleName = '',
        [Parameter(Mandatory)]
        [string]$Surname,
        [Parameter(Mandatory)]
        [string]$Domain
    )
    
    # Function to normalize special characters

    function Convert-SpecialCharacters {
        param([string]$InputString)
        
        $replacements = @{
            'ø' = 'o'
            'æ' = 'ae'
            'å' = 'a'
            'é' = 'e'
            'è' = 'e'
            'ê' = 'e'
            'ë' = 'e'
            'à' = 'a'
            'á' = 'a'
            'â' = 'a'
            'ä' = 'a'
            'ì' = 'i'
            'í' = 'i'
            'î' = 'i'
            'ï' = 'i'
            'ò' = 'o'
            'ó' = 'o'
            'ô' = 'o'
            'ö' = 'o'
            'ù' = 'u'
            'ú' = 'u'
            'û' = 'u'
            'ü' = 'u'
            'ý' = 'y'
            'ÿ' = 'y'
            'ñ' = 'n'
        }
        
        $normalizedString = $InputString.ToLower()
        foreach ($key in $replacements.Keys) {
            $normalizedString = $normalizedString.Replace($key, $replacements[$key])
        }
        
        return $normalizedString
    }
    
    # Clean and normalize input
    $GivenName = Convert-SpecialCharacters -InputString $GivenName.Trim()
    $MiddleName = Convert-SpecialCharacters -InputString $MiddleName.Trim()
    $Surname = Convert-SpecialCharacters -InputString $Surname.Trim()
    
    # Generate username (givenName.middleInitial.surname@domain.com)
    $middleInitial = if ($MiddleName) { ".$($MiddleName.Substring(0,1))." } else { "." }
    $username = "$GivenName$middleInitial$Surname@$Domain"
    
    # Remove any special characters and replace spaces
    $username = $username -replace '[^a-zA-Z0-9@._-]', ''
    
    # Ensure the local part (before @) is not longer than 20 characters
    $parts = $username -split '@'
    if ($parts[0].Length -gt 20) {
        $parts[0] = $parts[0].Substring(0, 20)
        $username = "$($parts[0])@$($parts[1])"
    }
    
    return $username
}

function New-BulkADUsers {
    param(
        [Parameter(Mandatory)]
        [string]$CsvPath,
        [Parameter(Mandatory)]
        [string]$Domain,
        [string]$LogPath = "user_creation_log.txt"
    )
    
    # Import CSV
    $users = Import-Csv -Path $CsvPath
    
    # Initialize log
    $log = @()
    
    foreach ($user in $users) {
        try {
            # Generate username
            $upn = New-StandardUsername -GivenName $user.GivenName `
                                        -MiddleName $user.MiddleName `
                                        -Surname $user.Surname `
                                        -Domain $Domain
            
            $samAccountName = ($upn -split '@')[0]
            
            # Check if user exists
            if (Test-ADUserExists -SamAccountName $samAccountName) {
                $log += "SKIP: User $samAccountName already exists"
                continue
            }
            
            # Generate random password
            $password = New-RandomPassword
            
            # Prepare user properties
            $userProperties = @{
                SamAccountName       = $samAccountName
                UserPrincipalName   = $upn
                Name                = "$($user.GivenName) $($user.Surname)"
                GivenName           = $user.GivenName
                Surname            = $user.Surname
                DisplayName        = "$($user.GivenName) $($user.Surname)"
                Department         = $user.Department
                Title              = $user.Title
                Office             = $user.Office
                AccountPassword    = (ConvertTo-SecureString $password -AsPlainText -Force)
                Enabled            = $true
                ChangePasswordAtLogon = $true
            }
            
            # Create user
            New-ADUser @userProperties
            $log += "SUCCESS: Created user $samAccountName with password: $password"
        }
        catch {
            $log += "ERROR: Failed to create user from record: $($user.GivenName) $($user.Surname). Error: $_"
        }
    }
    
    # Save log
    $log | Out-File -FilePath $LogPath
}

New-BulkADUsers -CsvPath "C:\Users\adm_helgeovs\Desktop\DCST1006\ADUsers.txt" -Domain "InfraIT.sec" -LogPath "C:\Users\adm_helgeovs\Desktop\DCST1006\user_log.txt"
# 