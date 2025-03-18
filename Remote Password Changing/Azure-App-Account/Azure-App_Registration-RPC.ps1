<#
.SYNOPSIS
    Automates the management of Azure App Registration client secrets by generating a new password and removing only expired credentials.

.DESCRIPTION
    This script is designed to streamline the password lifecycle management for Azure App Registrations. It performs the following operations:
    
    - **Authentication:** Logs into Azure using a Service Principal.
    - **Secret Cleanup:** Identifies and removes only truly expired client secrets, ensuring that valid credentials remain untouched.
    - **Password Generation:** Creates a new client secret for the specified App Registration.
    - **Expiration Management:** Uses a predefined static expiration period for the new client secret, ensuring compliance with security policies.
    - **Logging:** Records all actions, including authentication attempts, password generation, and secret removals, to a log file.
    - **Secret Server Integration:** Returns the newly generated password and its expiration date as DataItems, allowing Delinea Secret Server to store and manage them.

.PARAMETER $args[0]
    The Secret Name associated with the new client secret.
    - This will be used as the identifier for the secret.
    - Passed dynamically as an argument when executing the script.

.PARAMETER $args[1]
    The Object ID of the Azure App Registration for which the secret is being managed.

.PARAMETER $args[2]
    The Service Principal Application ID used to authenticate to Azure.

.PARAMETER $args[3]
    The Service Principal Secret for authentication.

.NOTES
    - The script only removes expired client secrets to prevent unintended deletions.
    - The expiration period is **hardcoded** in the script and can be adjusted by modifying `$ExpirationDays`.
    - This script is optimized for use with **Delinea Secret Server**, integrating seamlessly with its API to update stored secrets.

.OUTPUTS
    A PSObject containing:
    - "password": The newly generated password for the Azure App Registration.
    - "Expiration": The expiration date of the new password, formatted as `YYYY-MM-DD HH:mm:ss`.

.EXAMPLE
    # Example execution:
    .\Script.ps1 "MyAppSecret" "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy" "SuperSecretKey"

    # Expected Output in Secret Server:
    password    : AbCdE1!@#Xyz
    Expiration  : 2025-09-14 10:45:00
#>

# Static values (hardcoded)
$TenantId = "YOURTENANTVALUE"  # Azure Entra ID Tenant ID
$EnableLogging = $true  # Log function enable/disable
$RemoveExpiredSecrets = $true  # Only remove expired secrets
$LogFilePath = "C:\temp\Logs\AppPasswordLog.txt"  # Log file path
$ExpirationDays = 180  # Default to 180 days (6 months) # Set your desired expiration duration (Allowed: 90, 180, 365, 545, 730 days)

# Argument values passed from Secret Server
$SecretName = $args[0] # The name of the secret to be generated
$ObjectId = $args[1]  # The Object ID of the App Registration
$AuthAppId = $args[2]  # Service Principal Object ID
$AuthSecret = $args[3]  # Service Principal Secret

# Logging Function
function Write-LogEntry {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to console
    Write-Host $logEntry -ForegroundColor Gray

    # Write to log file if logging is enabled
    if ($EnableLogging) {
        Add-Content -Path $LogFilePath -Value $logEntry
    }
}

# Function to remove expired client secrets
function Remove-ExpiredSecrets {
    param (
        [string]$ObjectId
    )

    Write-LogEntry "Checking for expired secrets..."
    
    # Retrieve existing secrets
    $ExistingSecrets = Get-AzADAppCredential -ObjectId $ObjectId

    foreach ($secret in $ExistingSecrets) {
        # Check if the secret's expiration date is in the past
        if ($secret.EndDate -lt (Get-Date)) {
            Write-LogEntry "Removing expired secret with ID: $($secret.KeyId) (Expired on $($secret.EndDate))"
            Remove-AzADAppCredential -ObjectId $ObjectId -KeyId $secret.KeyId
        } else {
            Write-LogEntry "Secret with ID: $($secret.KeyId) is still valid (Expires on $($secret.EndDate)). Keeping it."
        }
    }
    Write-LogEntry "Expired secrets removal process completed."
}

# Start logging
Write-LogEntry "Script execution started."
Write-LogEntry "Logging enabled: $EnableLogging"
Write-LogEntry "Authenticating to Azure with Service Principal: $AuthAppId"

# Authenticate using the secondary account (Service Principal)
try {
    $securePassword = ConvertTo-SecureString $AuthSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($AuthAppId, $securePassword)

    $null = Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $credential | Out-Null
    Write-LogEntry "Successfully authenticated to Azure."
} catch {
    Write-LogEntry "Failed to authenticate to Azure: $_" -Level "ERROR"
    exit 1
}

# Remove expired secrets (if enabled)
if ($RemoveExpiredSecrets) {
    Remove-ExpiredSecrets -ObjectId $ObjectId
}

# Determine expiration date using the static expiration value
$StartDate = Get-Date
$EndDate = $StartDate.AddDays($ExpirationDays)
$FormattedExpiration = $EndDate.ToString("yyyy-MM-dd HH:mm:ss") # Format for readability
Write-LogEntry "Password expiration set to $ExpirationDays days (Expires: $FormattedExpiration)"

# Generate a new password credential with a custom name
try {
    Write-LogEntry "Generating a new password for Object ID: $ObjectId with name '$SecretName'"
    $EncodedSecretName = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($SecretName))
    $PasswordCredential = New-AzADAppCredential -ObjectId $ObjectId -StartDate $StartDate -EndDate $EndDate -CustomKeyIdentifier $EncodedSecretName
    Write-LogEntry "Successfully generated new password."
} catch {
    Write-LogEntry "Failed to generate password: $_" -Level "ERROR"
    exit 1
}

# Retrieve the generated password
$SecretValue = $PasswordCredential.SecretText

if (-not $SecretValue) {
    Write-LogEntry "Warning: SecretText is empty or null!" -Level "WARNING"
    exit 1
} else {
    Write-LogEntry "Successfully retrieved SecretText."
}

# Create a new PSObject and write the values back to Secret Server
$dataItem = New-Object –TypeName PSObject
$dataItem | Add-Member -MemberType NoteProperty -Name "password" -Value $SecretValue # Uses the consumed value from Azure
$dataItem | Add-Member -MemberType NoteProperty -Name "Expiration" -Value $FormattedExpiration  # Write expiration of secret to a field call "Expiration"

Write-LogEntry "Returning DataItems with updated password and expiration date."

return $dataItem