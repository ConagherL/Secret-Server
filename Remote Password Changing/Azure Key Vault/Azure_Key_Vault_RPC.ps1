# Args: $clientid $clientSecret $tenantID $vault $secret $newpassword
$clientID = $args[0]
$clientSecret = $args[1]
$tenantID = $args[2]
$AKVaultName = $args[3]
$AKSecretName = $args[4]
$NewPassword = $args[5]

# Validate input parameters
if (-not $clientID -or -not $clientSecret -or -not $tenantID -or -not $AKVaultName -or -not $AKSecretName -or -not $NewPassword) {
    throw "Missing one or more required arguments: clientID, clientSecret, tenantID, vaultName, secretName, or newPassword."
}

# Construct request body for token retrieval
$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://vault.azure.net/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
}

# Fetch OAuth token
try {
    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
    if (-not $TokenResponse.access_token) {
        throw "Token retrieval succeeded but no access token was found."
    }
} catch {
    throw "Failed to retrieve OAuth token. Error: $_"
}

# Prepare headers
$headers = @{
    Authorization = "Bearer $($TokenResponse.access_token)"
    "Content-Type" = "application/json"
}

# Construct AKV secret URL
$akvSecretURL = "https://$AKVaultName.vault.azure.net/secrets/$AKSecretName/?api-version=7.2"

# Fetch existing secret value
try {
    $Data = Invoke-RestMethod -Headers $headers -Uri $akvSecretURL -Method Get
    if (-not $Data.value) {
        throw "No value found for the secret '$AKSecretName'."
    }
    $SecretValue = $Data.value
} catch {
    throw "Failed to retrieve existing secret value. Error: $_"
}

# Check and update secret if needed
try {
    if ($SecretValue -ne $NewPassword) {
        $json = @{
            value = $NewPassword
        } | ConvertTo-Json -Depth 1
        Invoke-RestMethod -Headers $headers -Uri $akvSecretURL -Method PUT -Body $json
    }
} catch {
    throw "Failed to update the secret '$AKSecretName'. Error: $_"
}
