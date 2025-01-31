# Variables
$CyberArkURL = ""
$Username    = ""
$Password    = ""
$Headers     = @{}  # to be populated after auth
$SearchKeywords = "SEARCHVALUE"

# Authenticate
$AuthURI = "$CyberArkURL/PasswordVault/API/Auth/Cyberark/Logon"
$RequestBody = @{
    username = $Username
    password = $Password
}
try {
    $AuthResponse = Invoke-RestMethod -Uri $AuthURI -Method POST -Body ($RequestBody | ConvertTo-Json) -ContentType "application/json"
    $Token = $AuthResponse
    Write-Host "Authenticated. Token: $Token"
} catch {
    Write-Host "Authentication failed: $($_.Exception.Message)"
    return
}

$Headers = @{
    "Authorization" = $Token
    "Content-Type"  = "application/json"
}

$EncodedSearch = [System.Net.WebUtility]::UrlEncode($SearchKeywords)


$AccountsURI = "$CyberArkURL/PasswordVault/api/accounts?search=$EncodedSearch&limit=100"

Write-Host "Querying accounts with search='$SearchKeywords'"
try {
    $AllAccountsData = Invoke-RestMethod -Uri $AccountsURI -Headers $Headers -Method GET
    Write-Host "Retrieved $($AllAccountsData.value.Count) accounts matching search '$SearchKeywords'"
} catch {
    Write-Host "Failed to query accounts: $($_.Exception.Message)"
    return
}


$AllAccountsData.value | Select-Object id, name, safeName, userName, platformId | Format-Table
