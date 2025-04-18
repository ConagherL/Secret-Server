<#
.SYNOPSIS
    Rotates an Azure App Registration client secret.

.DESCRIPTION
    This script performs the following actions:
    - Authenticates to Azure using a Service Principal.
    - Optionally removes credentials from the App Registration that match the secret name:
        * Only expired credentials (default)
        * All credentials matching the name (if override enabled)
    - Generates a new client secret for the given App Registration.
    - Logs all operations and supports optional debugging mode.

.PARAMETER (args[0]) SecretName
    The name of the client secret to generate.

.PARAMETER (args[1]) ObjectId
    The Object ID of the Azure App Registration.

.PARAMETER (args[2]) AuthAppId
    The Application ID (Client ID) of the Service Principal used to authenticate.

.PARAMETER (args[3]) AuthSecret
    The client secret of the Service Principal used to authenticate.

.PARAMETER (args[4]) TenantId
    The Azure AD Tenant ID.

.NOTES
    Requires Az.Accounts and Az.Resources modules.
    Final output must be DataItems only.
#>

$EnableLogging = $true
$EnableDebugLogging = $false
$RemoveExpiredSecretsOnly = $false   # Removes only expired secrets that match the name
$RemoveMatchingSecretsOnly = $false # Removes all matching secrets regardless of expiration

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$LogFilePath = "C:\temp\Logs\AppPassword-Rotation-Log-$timestamp.txt"

function Write-LogMessage {
    param ([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$ts] [$Level] $Message"
    if ($EnableLogging) { Add-Content -Path $LogFilePath -Value $entry }
    if ($EnableDebugLogging -or $Level -eq "ERROR") { Write-Host $entry }
}

Write-LogMessage "Script execution started."

if ($EnableDebugLogging) {
    Write-LogMessage "=== ARGUMENT DEBUGGING ==="
    for ($i = 0; $i -lt $args.Count; $i++) {
        Write-LogMessage "Argument $($i + 1): $($args[$i])"
    }
    Write-LogMessage "=============================="
}

$SecretName       = $args[0].Trim()
$ObjectId         = $args[1].Trim()
$AuthAppId        = $args[2].Trim()
$AuthSecret       = $args[3].Trim()
$TenantId         = $args[4].Trim()

$ExpirationDays = 180
$StartDate = Get-Date
$EndDate = $StartDate.AddDays($ExpirationDays)
$FormattedExpiration = $EndDate.ToString("yyyy-MM-dd HH:mm:ss")

function Remove-ExpiredSecrets {
    param (
        [string]$ObjectId,
        [string]$TargetSecretName
    )

    $targetKeyId = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($TargetSecretName))
    Write-LogMessage "Checking for secrets with name '$TargetSecretName'..."
    $ExistingSecrets = Get-AzADAppCredential -ObjectId $ObjectId

    foreach ($secret in $ExistingSecrets) {
        try {
            if (-not $secret.CustomKeyIdentifier) {
                Write-LogMessage "Skipping secret with ID: $($secret.KeyId) — no CustomKeyIdentifier set."
                continue
            }

            $customKeyIdEncoded = [System.Convert]::ToBase64String($secret.CustomKeyIdentifier)
            $match = ($customKeyIdEncoded -eq $targetKeyId)
            $expired = ($secret.EndDate -ne $null -and $secret.EndDate -lt (Get-Date))

            if ($EnableDebugLogging) {
                Write-LogMessage "DEBUG: Secret $($secret.KeyId) — Match=$match, Expired=$expired"
            }

            if ($match -and (($RemoveMatchingSecretsOnly -eq $true) -or ($RemoveExpiredSecretsOnly -eq $true -and $expired))) {
                Write-LogMessage "Removing matching secret with ID: $($secret.KeyId)"
                try {
                    Remove-AzADAppCredential -ObjectId $ObjectId -KeyId $secret.KeyId -ErrorAction Stop | Out-Null
                } catch {
                    Write-LogMessage "Failed to remove secret with ID $($secret.KeyId): $_" -Level "ERROR"
                    throw "Unable to cleanup secret $TargetSecretName"
                }
            }
        } catch {
            Write-LogMessage "Error during secret cleanup loop: $_" -Level "ERROR"
            throw "Unable to cleanup secret $TargetSecretName"
        }
    }

    Write-LogMessage "Secret removal complete for '$TargetSecretName'."
}

try {
    Write-LogMessage "Authenticating with Service Principal: $AuthAppId"
    $secPassword = ConvertTo-SecureString $AuthSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($AuthAppId, $secPassword)
    Connect-AzAccount -ServicePrincipal -TenantId $TenantId -Credential $credential | Out-Null
    Write-LogMessage "Authentication successful."
} catch {
    Write-LogMessage "Authentication failed: $_" -Level "ERROR"
    exit 1
}

try {
    Remove-ExpiredSecrets -ObjectId $ObjectId -TargetSecretName $SecretName
} catch {
    Write-LogMessage "Unable to cleanup secret '$SecretName'. Aborting." -Level "ERROR"
    exit 1
}

try {
    Write-LogMessage "Generating new password for App Reg ObjectId: $ObjectId with name '$SecretName'"
    $EncodedSecretName = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($SecretName))
    $PasswordCredential = New-AzADAppCredential -ObjectId $ObjectId -StartDate $StartDate -EndDate $EndDate -CustomKeyIdentifier $EncodedSecretName
    $SecretValue = $PasswordCredential.SecretText
    if (-not $SecretValue) { throw "SecretText is null or empty" }
    Write-LogMessage "Secret generated. Expires: $FormattedExpiration"
} catch {
    Write-LogMessage "Failed to generate secret: $_" -Level "ERROR"
    exit 1
}

$dataItem = New-Object -TypeName PSObject
$dataItem | Add-Member -MemberType NoteProperty -Name "password" -Value $SecretValue
$dataItem | Add-Member -MemberType NoteProperty -Name "Expiration" -Value $FormattedExpiration
return $dataItem