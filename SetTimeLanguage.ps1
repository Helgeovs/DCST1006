Set-TimeZone -Id "W. Europe Standard Time"
$CurrentLanguage = New-WinUserLanguageList -Language "nb-NO"
$CurrentLanguage[0].InputMethodTips.Add("0414:00000414")
Set-WinUserLanguageList -LanguageList $CurrentLanguage -Force
