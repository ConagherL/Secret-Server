<#
.SYNOPSIS 
Validates whether the current value of a secret in Azure Key Vault matches the current password using the latest version of the secret.

.DESCRIPTION
The script:
1. Authenticates to Azure using client credentials to obtain an OAuth 2.0 token.
2. Fetches all versions of a specified secret from Azure Key Vault.
3. Identifies the latest version and retrieves its value.
4. Validates the retrieved secret value against the provided current password.
5. Introduces a sleep delay to allow Azure Key Vault to propagate changes before validation.
6. Throws an error for failures or completes without error for successful validation.

.PARAMETERS
$args[0] - Client ID: The Azure AD application/client ID for authentication. (Example: $[1]$client-id)
$args[1] - Client Secret: The client secret associated with the Azure AD application. (Example: $[1]$client-secret)
$args[2] - Tenant ID: The Azure AD tenant ID for authentication. (Example: $[1]$tenant-id)
$args[3] - Vault Name: The name of the Azure Key Vault containing the secret. (Example: $vault)
$args[4] - Secret Name: The name of the secret to validate. (Example: $username)
$args[5] - Current Password: The current password to validate against the Azure Key Vault secret. (Example: $password)

.EXAMPLE
.\Validate-AzureKeyVaultSecret.ps1 `
    $[1]$client-id `
    $[1]$client-secret `
    $[1]$tenant-id `
    $vault `
    $username `
    $password
#>


# Define log file (commented out logging)
#$logFile = "C:\logs\heartbeat_debug.log"
#if (-not (Test-Path $logFile)) {
#    New-Item -Path $logFile -ItemType File -Force | Out-Null
#}

# Log function (commented out logging)
#function Log-Message {
#    param (
#        [string]$Message
#    )
#    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
#    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
#}

# Log start of script (commented out logging)
#Log-Message "Validation script started."

# Read arguments
$clientID = $args[0]        # Azure AD application/client ID
$clientSecret = $args[1]    # Azure AD application client secret
$tenantID = $args[2]        # Azure AD tenant ID
$AKVaultName = $args[3]     # Azure Key Vault name
$secretName = $args[4]      # Secret name to validate
$currentPassword = $args[5] # Current password to validate

# Construct request body for token retrieval
$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://vault.azure.net/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
}

#Log-Message "Requesting token from Azure..."

# Fetch OAuth token
try {
    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
    #Log-Message "Token retrieved successfully."
} catch {
    #Log-Message "Error retrieving token: $_"
    throw "Token retrieval failed: $_"
}

# Prepare headers for API requests
$headers = @{
    Authorization = "Bearer $($TokenResponse.access_token)"
    "Content-Type" = "application/json"
}

# Add a sleep delay to allow Azure Key Vault to propagate changes
$sleepDelay = 5
#Log-Message "Sleeping for ${sleepDelay} seconds to allow Azure Key Vault to propagate changes."
Start-Sleep -Seconds $sleepDelay

# Fetch all versions of the secret
$versionsURL = "https://$AKVaultName.vault.azure.net/secrets/$secretName/versions?api-version=7.2"
#Log-Message "Fetching all versions of the secret: $versionsURL"

try {
    $VersionsResponse = Invoke-RestMethod -Headers $headers -Uri $versionsURL -Method GET
    $LatestVersion = $VersionsResponse.value | Sort-Object { $_.attributes.updated } -Descending | Select-Object -First 1
    $LatestVersionID = ($LatestVersion.id -split '/')[-1]  # Extract only the version ID
    #Log-Message "Latest version ID: $LatestVersionID"
} catch {
    #Log-Message "Error retrieving secret versions: $_"
    throw "Failed to fetch secret versions: $_"
}

# Construct the URL for the latest version of the secret
$latestSecretURL = "https://$AKVaultName.vault.azure.net/secrets/$secretName/$LatestVersionID/?api-version=7.2"
#Log-Message "Constructed URL for latest secret: $latestSecretURL"

# Fetch the value of the latest version
try {
    #Log-Message "Fetching the latest version of the secret: $latestSecretURL"
    $LatestSecretResponse = Invoke-RestMethod -Headers $headers -Uri $latestSecretURL -Method GET
    $SecretValue = $LatestSecretResponse.value.Trim()
    #Log-Message "Retrieved secret value: '$SecretValue'"
} catch {
    #Log-Message "Error retrieving the latest version of the secret: $_"
    throw "Failed to fetch the latest version of the secret: $_"
}

# Log the comparison for debugging (commented out logging)
#$SecretValueTrimmed = [string]$SecretValue.Trim()
#$currentPasswordTrimmed = [string]$currentPassword.Trim()

#Log-Message "Sanitized values for comparison -> Secret: '$SecretValueTrimmed', Password: '$currentPasswordTrimmed'"

# Explicitly validate the retrieved value
$SecretValueTrimmed = [string]$SecretValue.Trim()
$currentPasswordTrimmed = [string]$currentPassword.Trim()

if ($SecretValueTrimmed -ceq $currentPasswordTrimmed) {
    #Log-Message "Validation successful: Secret matches the provided password."
} else {
    #Log-Message "Validation failed: Secret does not match the provided password."
    throw "Validation failed: Secret does not match the provided password."
}

#Log-Message "Validation script completed successfully."
