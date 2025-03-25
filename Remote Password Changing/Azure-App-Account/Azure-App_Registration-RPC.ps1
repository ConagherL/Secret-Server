<#
.SYNOPSIS
    Generates a new client secret for an Azure App Registration and updates Azure Key Vault secrets.

.DESCRIPTION
    This script performs the following actions:
    - Authenticates to Azure using a Service Principal.
    - Generates a new client secret for an Azure App Registration.
    - Updates specified Azure Key Vault(s) with the new client secret.
    - Removes expired secrets from the App Registration that match the current SecretName.
    - Logs all actions and errors to a specified log file.
    - Fails fast if any Azure Key Vault update fails.

.PARAMETER SecretName
    The name of the secret to be created or updated in Azure Key Vault.

.PARAMETER ObjectId
    The Object ID of the Azure App Registration.

.PARAMETER AuthAppId
    The Application ID of the Service Principal used for authentication.

.PARAMETER AuthSecret
    The client secret of the Service Principal used for authentication.

.PARAMETER TenantId
    The Tenant ID of the Azure Active Directory.

.PARAMETER KeyVaultsCsv
    A comma-separated list of Azure Key Vault names where the secret should be updated.

.EXAMPLE
    .\Update-AppRegistrationSecret.ps1 -SecretName "MySecret" -ObjectId "12345" -AuthAppId "67890" -AuthSecret "abcdef" -TenantId "tenant123" -KeyVaultsCsv "vault1,vault2"

#>

# ===============================
# ARGUMENTS
# ===============================
$SecretName    = $args[0]
$ObjectId      = $args[1]
$AuthAppId     = $args[2]
$AuthSecret    = $args[3]
$TenantId      = $args[4]
$KeyVaultsCsv  = $args[5]

# ===============================
# STATIC CONFIGURATION
# ===============================
$ExpirationDays        = 180
$EnableLogging         = $true
$RemoveExpiredSecrets  = $true
$LogFilePath           = "C:\temp\Logs\AppPassword-AKVPassword-Log.txt"

# ===============================
# FUNCTIONS
# ===============================
function Write-LogMessage {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    Write-Host $logEntry -ForegroundColor Gray
    if ($EnableLogging) {
        Add-Content -Path $LogFilePath -Value $logEntry
    }
}

function Remove-ExpiredSecrets {
    param (
        [string]$ObjectId,
        [string]$TargetSecretName
    )

    $targetKeyId = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($TargetSecretName))
    Write-LogMessage "Checking for expired secrets with name '$TargetSecretName'..."

    $ExistingSecrets = Get-AzADAppCredential -ObjectId $ObjectId
    foreach ($secret in $ExistingSecrets) {
        if ($secret.CustomKeyIdentifier -eq $targetKeyId -and $secret.EndDate -lt (Get-Date)) {
            Write-LogMessage "Removing expired secret with ID: $($secret.KeyId)"
            Remove-AzADAppCredential -ObjectId $ObjectId -KeyId $secret.KeyId
        }
    }

    Write-LogMessage "Expired secret removal complete for '$TargetSecretName'."
}

function Update-AkvSecret {
    param (
        [string]$VaultName,
        [string]$SecretName,
        [string]$SecretValue,
        [datetime]$ExpirationDate
    )

    try {
        Write-LogMessage "Updating secret '$SecretName' in Azure Key Vault '$VaultName'..."

        $kvParams = @{
            VaultName   = $VaultName
            Name        = $SecretName
            SecretValue = (ConvertTo-SecureString $SecretValue -AsPlainText -Force)
            Expires     = $ExpirationDate
        }

        Set-AzKeyVaultSecret @kvParams | Out-Null
        Write-LogMessage "Secret '$SecretName' has been created or updated in Azure Key Vault '$VaultName'."
        return $true
    } catch {
        Write-LogMessage "Error while updating secret '$SecretName' in vault '$VaultName': $_" -Level "ERROR"
        return $false
    }
}

# ===============================
# START SCRIPT
# ===============================
Write-LogMessage "Script execution started."
Write-LogMessage "Authenticating to Azure with Service Principal: $AuthAppId"

try {
    $securePassword = ConvertTo-SecureString $AuthSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($AuthAppId, $securePassword)
    Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $credential | Out-Null
    Write-LogMessage "Successfully authenticated to Azure."
} catch {
    Write-LogMessage "Failed to authenticate to Azure: $_" -Level "ERROR"
    exit 1
}

if ($RemoveExpiredSecrets) {
    Remove-ExpiredSecrets -ObjectId $ObjectId -TargetSecretName $SecretName
}

$StartDate = Get-Date
$EndDate = $StartDate.AddDays($ExpirationDays)
$FormattedExpiration = $EndDate.ToString("yyyy-MM-dd HH:mm:ss")
Write-LogMessage "Password expiration set to $ExpirationDays days (Expires: $FormattedExpiration)"

try {
    Write-LogMessage "Generating new password for App Registration Object ID: $ObjectId with name '$SecretName'"
    $EncodedSecretName = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($SecretName))
    $PasswordCredential = New-AzADAppCredential -ObjectId $ObjectId -StartDate $StartDate -EndDate $EndDate -CustomKeyIdentifier $EncodedSecretName
    Write-LogMessage "Successfully generated new password."
} catch {
    Write-LogMessage "Failed to generate password: $_" -Level "ERROR"
    exit 1
}

$SecretValue = $PasswordCredential.SecretText
if (-not $SecretValue) {
    Write-LogMessage "Warning: Secret Value is empty or null!" -Level "WARNING"
    exit 1
}
Write-LogMessage "Successfully retrieved Secret Value."

# ===============================
# UPDATE AZURE KEY VAULTS
# ===============================
if ($KeyVaultsCsv) {
    $KeyVaultNames = $KeyVaultsCsv -split ',' | ForEach-Object { $_.Trim() }
    Write-LogMessage "Azure Key Vaults provided: $($KeyVaultNames -join ', ')"

    $akvFailed = $false
    foreach ($vault in $KeyVaultNames) {
        $result = Update-AkvSecret -VaultName $vault `
                                   -SecretName $SecretName `
                                   -SecretValue $SecretValue `
                                   -ExpirationDate $EndDate
        if (-not $result) {
            $akvFailed = $true
        }
    }

    if ($akvFailed) {
        Write-LogMessage "One or more Azure Key Vault updates failed. Aborting with error." -Level "ERROR"
        exit 1
    }
} else {
    Write-LogMessage "No Azure Key Vault names provided. Skipping AKV update."
}

# ===============================
# RETURN DATAITEMS
# ===============================
$dataItem = New-Object –TypeName PSObject
$dataItem | Add-Member -MemberType NoteProperty -Name "password" -Value $SecretValue
$dataItem | Add-Member -MemberType NoteProperty -Name "Expiration" -Value $FormattedExpiration

Write-LogMessage "Returning DataItems with updated password and expiration."
return $dataItem