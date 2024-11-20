<#
.SYNOPSIS 
This PowerShell script automates the management of secrets in Azure Key Vault (AKV). 
It retrieves a specified secret, compares its current value to a provided new value, and updates the secret if necessary.

.DESCRIPTION
The script performs the following steps:
1. Authenticates to Azure using Azure AD client credentials to obtain an OAuth 2.0 token.
2. Retrieves the current value of a specified secret from Azure Key Vault.
3. Compares the current secret value with a new value provided as an argument.
4. Updates the secret in Azure Key Vault if the values are different.
5. Includes enhanced error handling and detailed logging for better debugging.

.PARAMETERS
$args[0] - Client ID: The Azure AD application/client ID for authentication.
$args[1] - Client Secret: The client secret associated with the Azure AD application.
$args[2] - Tenant ID: The Azure AD tenant ID for authentication.
$args[3] - Vault Name: The name of the Azure Key Vault containing the secret.
$args[4] - Secret Name: The name of the secret to be retrieved and potentially updated.
$args[5] - New Password: The new value to set for the secret.

.NOTES
- The Azure AD application must have sufficient permissions for the Key Vault (e.g., "Set", "Get").
- Requires PowerShell 5.1 or later.
#>

# Define the log file path
$LogFilePath = "C:\Logs\Azure_Key_Vault_RPC.log"

# Initialize log file
if (-not (Test-Path $LogFilePath)) {
    New-Item -ItemType File -Path $LogFilePath -Force | Out-Null
}

# Logging Function
function Write-Log {
    param (
        [Parameter(Mandatory)]
        [string]$Message,

        [Parameter()]
        [ValidateSet('INFO', 'ERROR', 'WARNING', 'DEBUG')]
        [string]$Level = 'INFO'
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] $Message"
    Add-Content -Path $LogFilePath -Value $LogEntry
}

# Log start of script
Write-Log -Message "Azure Key Vault secret management script started." -Level "INFO"

# Args: $clientid $clientSecret $tenantID $vault $secret $newpassword
$clientID = $args[0]
$clientSecret = $args[1]
$tenantID = $args[2]
$AKVaultName = $args[3]
$AKSecretName = $args[4]
$NewPassword = $args[5]

# Validate input parameters
if (-not $clientID -or -not $clientSecret -or -not $tenantID -or -not $AKVaultName -or -not $AKSecretName -or -not $NewPassword) {
    $errorMessage = "Missing one or more required arguments: clientID, clientSecret, tenantID, vaultName, secretName, or newPassword."
    Write-Log -Message $errorMessage -Level "ERROR"
    throw $errorMessage
}

Write-Log -Message "Input parameters validated successfully." -Level "INFO"
Write-Log -Message "Parameters passed: ClientID=$clientID, TenantID=$tenantID, VaultName=$AKVaultName, SecretName=$AKSecretName, NewPassword=$NewPassword" -Level "DEBUG"

# Construct request body for token retrieval
$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://vault.azure.net/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
}

# Log request token details
Write-Log -Message "Requesting token with ClientID=$clientID and TenantID=$tenantID." -Level "DEBUG"

# Fetch OAuth token
try {
    Write-Log -Message "Attempting to retrieve OAuth token..." -Level "INFO"
    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$tenantID/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody
    if (-not $TokenResponse.access_token) {
        throw "Token retrieval succeeded but no access token was found."
    }
    Write-Log -Message "OAuth token retrieved successfully." -Level "INFO"
    Write-Log -Message "Token response details: $($TokenResponse | ConvertTo-Json -Depth 1)" -Level "DEBUG"
} catch {
    Write-Log -Message "Failed to retrieve OAuth token. Error: $_" -Level "ERROR"
    throw
}

# Prepare headers
$headers = @{
    Authorization = "Bearer $($TokenResponse.access_token)"
    "Content-Type" = "application/json"
}

# Log AKV access details
Write-Log -Message "Using VaultName=$AKVaultName to access SecretName=$AKSecretName." -Level "DEBUG"

# Construct AKV secret URL
$akvSecretURL = "https://$AKVaultName.vault.azure.net/secrets/$AKSecretName/?api-version=7.2"
Write-Log -Message "Constructed Secret URL: $akvSecretURL" -Level "DEBUG"

# Fetch existing secret value
try {
    Write-Log -Message "Attempting to retrieve existing secret value for '$AKSecretName'..." -Level "INFO"
    $Data = Invoke-RestMethod -Headers $headers -Uri $akvSecretURL -Method Get
    if (-not $Data.value) {
        throw "No value found for the secret '$AKSecretName'."
    }
    $SecretValue = $Data.value
    Write-Log -Message "Retrieved existing secret value successfully." -Level "INFO"
    Write-Log -Message "Current Secret Value: $SecretValue" -Level "DEBUG"
} catch {
    Write-Log -Message "Failed to retrieve existing secret value. Error: $_" -Level "ERROR"
    throw
}

# Check and update secret if needed
try {
    if ($SecretValue -ne $NewPassword) {
        Write-Log -Message "Existing secret value differs from the new value. Updating secret..." -Level "INFO"
        Write-Log -Message "New Password Value: $NewPassword" -Level "DEBUG"
        $json = @{
            value = $NewPassword
        } | ConvertTo-Json -Depth 1
        Invoke-RestMethod -Headers $headers -Uri $akvSecretURL -Method PUT -Body $json
        Write-Log -Message "Secret '$AKSecretName' updated successfully." -Level "INFO"
    } else {
        Write-Log -Message "Existing secret value matches the new value. No update needed." -Level "INFO"
    }
} catch {
    Write-Log -Message "Failed to update the secret '$AKSecretName'. Error: $_" -Level "ERROR"
    throw
}

# Log script completion
Write-Log -Message "Azure Key Vault secret management script completed successfully." -Level "INFO"
