<#
.SYNOPSIS
    Creates and manages Azure App Registration secrets using Microsoft Graph API.
.DESCRIPTION
    - Authenticates to Microsoft Graph.
    - Deletes existing secrets based on cleanup config.
    - Creates a new client secret with a defined expiration.
    - Returns secret to Secret Server RPC in expected format.
#>

# --- CONFIGURATION ---
$EnableLogging                = $true
$EnableDebugLogging           = $false
$EnableExpiredSecretCleanup   = $true   # Deletes secrets that match the name, are expired, and have the correct tag
$EnableFullNameMatchCleanup   = $false   # Deletes ALL secrets that match the name, regardless of expiration/tag
$ExpirationDays               = 180
$CustomKeyIdentifierTag       = "CreatedBy:SecretServer"

$timestamp    = Get-Date -Format "yyyyMMdd-HHmmss"
$LogRoot      = "C:\Temp\Logs\AppSecretManager"
$LogFilePath  = Join-Path -Path $LogRoot -ChildPath "AppSecret-Graph-Log-$timestamp.txt"

# Ensure the log directory exists
if ($EnableLogging -or $EnableDebugLogging) {
    if (-not (Test-Path -Path $LogRoot)) {
        New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
    }
}

function Write-LogMessage {
    param ([string]$Message, [string]$Level = "INFO")
    $ts = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$ts] [$Level] $Message"
    if ($EnableLogging) { Add-Content -Path $LogFilePath -Value $entry }
    if ($EnableDebugLogging -or $Level -eq "ERROR") { Write-Host $entry }
}

# --- INPUT ARGUMENTS ---
$SecretName   = $args[0].Trim()
$ObjectId     = $args[1].Trim()
$ClientId     = $args[2].Trim()
$ClientSecret = $args[3].Trim()
$TenantId     = $args[4].Trim()

Write-LogMessage "Script execution started."
Write-LogMessage "Creating secret: '$SecretName' for App ObjectId: $ObjectId"

# --- AUTHENTICATE TO GRAPH ---
try {
    $TokenUri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    $TokenBody = @{
        grant_type    = "client_credentials"
        scope         = "https://graph.microsoft.com/.default"
        client_id     = $ClientId
        client_secret = $ClientSecret
    }

    Write-LogMessage "Authenticating to Microsoft Graph..."
    $tokenResponse = Invoke-RestMethod -Method Post -Uri $TokenUri -Body $TokenBody
    $AccessToken = $tokenResponse.access_token
    if (-not $AccessToken) { throw "Access token is null or empty." }
    Write-LogMessage "Authentication successful."
} catch {
    Write-LogMessage "Graph token request failed: $_" -Level "ERROR"
    exit 1
}

# --- FUNCTION: Delete expired and has customkeyidentifier set---
function Remove-ExpiredSecrets {
    Write-LogMessage "Checking for expired secrets with displayName '$SecretName' and tag '$CustomKeyIdentifierTag'..."
    $ListUri = "https://graph.microsoft.com/v1.0/applications/$ObjectId"
    $Headers = @{ Authorization = "Bearer $AccessToken" }

    try {
        $appData = Invoke-RestMethod -Uri $ListUri -Headers $Headers -Method Get

        foreach ($cred in $appData.passwordCredentials) {
            $end = ([datetime]$cred.endDateTime).ToUniversalTime()
            $decodedIdentifier = ""
            try {
                $decodedIdentifier = [System.Text.Encoding]::UTF8.GetString(
                    [System.Convert]::FromBase64String($cred.customKeyIdentifier)
                )
            } catch { $decodedIdentifier = "" }

            if (
                $cred.displayName -ieq $SecretName -and
                $end -lt (Get-Date).ToUniversalTime() -and
                $decodedIdentifier -eq $CustomKeyIdentifierTag
            ) {
                Write-LogMessage "Deleting expired secret:"
                Write-LogMessage "  KeyId     = $($cred.keyId)"
                Write-LogMessage "  Expires   = $end (UTC)"
                Write-LogMessage "  Tag Match = $($decodedIdentifier -eq $CustomKeyIdentifierTag)"
                if ($EnableDebugLogging) {
                    Write-LogMessage "--- Raw Secret Object ---"
                    Write-LogMessage ($cred | ConvertTo-Json -Depth 3)
                    Write-LogMessage "-------------------------"
                }

                $deleteUri = "https://graph.microsoft.com/v1.0/applications/$ObjectId/removePassword"
                $deleteHeaders = @{
                    Authorization = "Bearer $AccessToken"
                    "Content-Type" = "application/json"
                }
                $body = @{ keyId = $cred.keyId } | ConvertTo-Json
                try {
                    Invoke-RestMethod -Method Post -Uri $deleteUri -Headers $deleteHeaders -Body $body
                } catch {
                    Write-LogMessage "Failed to delete expired secret KeyId=$($cred.keyId): $_" -Level "ERROR"
                }
            } elseif ($cred.displayName -ieq $SecretName) {
                Write-LogMessage "Skipping KeyId=$($cred.keyId): Expired=$($end -lt (Get-Date).ToUniversalTime()), TagMatch=$($decodedIdentifier -eq $CustomKeyIdentifierTag)"
            }
        }
    } catch {
        Write-LogMessage "Failed during expired secret cleanup: $_" -Level "ERROR"
    }
}

# --- FUNCTION: Delete all that match the SecretName ---
function Remove-AllSecretsByName {
    Write-LogMessage "Force-deleting ALL secrets with displayName '$SecretName' regardless of expiration or tag..."
    $ListUri = "https://graph.microsoft.com/v1.0/applications/$ObjectId"
    $Headers = @{ Authorization = "Bearer $AccessToken" }

    try {
        $appData = Invoke-RestMethod -Uri $ListUri -Headers $Headers -Method Get

        foreach ($cred in $appData.passwordCredentials) {
            if ($cred.displayName -ieq $SecretName) {
                Write-LogMessage "Force-deleting secret:"
                Write-LogMessage "  KeyId   = $($cred.keyId)"
                Write-LogMessage "  Expires = $($cred.endDateTime)"
                if ($EnableDebugLogging) {
                    Write-LogMessage "--- Raw Secret Object ---"
                    Write-LogMessage ($cred | ConvertTo-Json -Depth 3)
                    Write-LogMessage "-------------------------"
                }

                $deleteUri = "https://graph.microsoft.com/v1.0/applications/$ObjectId/removePassword"
                $deleteHeaders = @{
                    Authorization = "Bearer $AccessToken"
                    "Content-Type" = "application/json"
                }
                $body = @{ keyId = $cred.keyId } | ConvertTo-Json
                try {
                    Invoke-RestMethod -Method Post -Uri $deleteUri -Headers $deleteHeaders -Body $body
                } catch {
                    Write-LogMessage "Failed to delete KeyId=$($cred.keyId): $_" -Level "ERROR"
                }
            }
        }
    } catch {
        Write-LogMessage "Failed during full name-match cleanup: $_" -Level "ERROR"
    }
}

# --- INVOKE CLEANUP SEQUENCES ---
if ($EnableExpiredSecretCleanup) {
    Remove-ExpiredSecrets
}
if ($EnableFullNameMatchCleanup) {
    Remove-AllSecretsByName
}

# --- DATES ---
$StartDate = (Get-Date).AddMinutes(1)
$EndDate   = $StartDate.AddDays($ExpirationDays)
$FormattedExpiration = $EndDate.ToString("yyyy-MM-dd HH:mm:ss")
Write-LogMessage "StartDate: $StartDate"
Write-LogMessage "EndDate  : $EndDate"

# --- ENCODE customKeyIdentifier FOR NEW SECRET ---
$identifierBytes   = [System.Text.Encoding]::UTF8.GetBytes($CustomKeyIdentifierTag)
$encodedIdentifier = [Convert]::ToBase64String($identifierBytes)

# --- CREATE SECRET ---
try {
    $AddUri = "https://graph.microsoft.com/v1.0/applications/$ObjectId/addPassword"
    $Headers = @{
        "Authorization" = "Bearer $AccessToken"
        "Content-Type"  = "application/json"
    }

    $AddBody = @{
        passwordCredential = @{
            displayName         = $SecretName
            startDateTime       = $StartDate.ToString("o")
            endDateTime         = $EndDate.ToString("o")
            customKeyIdentifier = $encodedIdentifier
        }
    } | ConvertTo-Json -Depth 3

    Write-LogMessage "Sending /addPassword request..."
    $response = Invoke-RestMethod -Method Post -Uri $AddUri -Headers $Headers -Body $AddBody

    if ($EnableDebugLogging) {
        Write-LogMessage "=== RAW GRAPH RESPONSE ==="
        Write-LogMessage ($response | ConvertTo-Json -Depth 3)
        Write-LogMessage "==========================="
    }

    if ($EnableDebugLogging) {
        Write-LogMessage "Secret created: KeyId=$($response.keyId), Hint=$($response.hint), Expires=$($response.endDateTime)"
    }

    if (-not $response.secretText) {
        Write-LogMessage "SecretText is null or empty. RPC failure." -Level "ERROR"
        throw "RPC Failure: Secret value not found."
    }
} catch {
    Write-LogMessage "Failed to create new secret: $_" -Level "ERROR"
    exit 1
}

# --- RETURN DATA TO SECRET SERVER ---
$dataItem = New-Object -TypeName PSObject
$dataItem | Add-Member -MemberType NoteProperty -Name "password"   -Value $response.secretText
$dataItem | Add-Member -MemberType NoteProperty -Name "Expiration" -Value $FormattedExpiration
return $dataItem