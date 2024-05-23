<#
.SYNOPSIS
    Updates specified field values in Secret Server based on given criteria.

.DESCRIPTION
    This script authenticates with Secret Server, retrieves all secrets, and updates the specified field with a new value for secrets that match the given criteria.

.PARAMETER SearchFieldValue
    The value to search for in the specified field. Default is "abc.local".

.PARAMETER FieldName
    The name of the field to search and update. Default is "Domain".

.PARAMETER NewValue
    The new value to set in the specified field. Default is "happy.local".

.PARAMETER OtpCode
    The OTP code for authentication if the UseOtp switch is used.

.PARAMETER UseOtp
    Switch to use OTP for authentication.

.EXAMPLE
    .\UpdateSecretField.ps1 -SearchFieldValue "abc.local" -FieldName "Domain" -NewValue "happy.local"
    Updates the 'Domain' field value from "abc.local" to "happy.local" in all matching secrets.

.EXAMPLE
    .\UpdateSecretField.ps1 -SearchFieldValue "olduser" -FieldName "Username" -NewValue "newuser"
    Updates the 'Username' field value from "olduser" to "newuser" in all matching secrets.

.EXAMPLE
    .\UpdateSecretField.ps1 -SearchFieldValue "abc.local" -FieldName "Domain" -NewValue "happy.local" -OtpCode "123456" -UseOtp
    Uses OTP authentication to update the 'Domain' field value from "abc.local" to "happy.local" in all matching secrets.

.NOTES
    The script generates a log file in C:\temp with the name Update_Secret_Field_<FieldName>_<timestamp>.txt.

#>

param (
    [string]$SearchFieldValue = "abc.local",
    [string]$FieldName = "Domain",
    [string]$NewValue = "happy.local",
    [string]$OtpCode = "",
    [switch]$UseOtp
)

# Generate dynamic log file path using the FieldName parameter
$LogFilePath = "C:\temp\Update_Secret_Field_${FieldName}_$((Get-Date).ToString('yyyyMMdd_HHmmss')).txt"

# Function to write log messages to a file and the host
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $LogFilePath -Value $logMessage
    Write-Host $logMessage
}

# Secret Server API base URL
$baseUrl = "https://blt.secretservercloud.com"

# Authenticate with Secret Server using the provided credentials or OTP
if ($UseOtp) {
    if (-not $OtpCode) {
        Write-Log "OTP code is required when using -UseOtp switch."
        exit
    }

    try {
        $authResponse = Invoke-RestMethod -Uri "$baseUrl/oauth2/token" -Method Post -Body @{
            grant_type = "password"
            username = "otp_user" # Replace with the OTP user if needed
            password = $OtpCode
        }
        Write-Log "Authentication successful using OTP."
    } catch {
        Write-Log "Authentication failed using OTP: $_"
        exit
    }
} else {
    $credential = Get-Credential

    try {
        $authResponse = Invoke-RestMethod -Uri "$baseUrl/oauth2/token" -Method Post -Body @{
            grant_type = "password"
            username = $credential.UserName
            password = $credential.GetNetworkCredential().Password
        }
        Write-Log "Authentication successful using credentials."
    } catch {
        Write-Log "Authentication failed using credentials: $_"
        exit
    }
}

# Extract the access token
$accessToken = $authResponse.access_token

# Set the authorization header
$headers = @{
    Authorization = "Bearer $accessToken"
}

# Initialize a counter for updated secrets
$updatedSecretsCount = 0

# Function to update a secret if it has the specified field with the specified value
function Update-Secret {
    param (
        [int]$secretId
    )

    try {
        $secret = Invoke-RestMethod -Uri "$baseUrl/api/v1/secrets/$secretId" -Headers $headers -Method Get
        $secretName = $secret.name
    } catch {
        Write-Log "Failed to retrieve secret with ID $secretId : $_"
        return
    }

    # Check if the secret has the specified field with the specified value
    $fieldToUpdate = $secret.items | Where-Object { $_.fieldName -eq $FieldName -and $_.itemValue -eq $SearchFieldValue }

    if ($fieldToUpdate) {
        # Update the field to the new value
        $fieldToUpdate.itemValue = $NewValue

        # Prepare the updated secret body
        $updatedSecretBody = @{
            id = $secret.id
            name = $secret.name
            secretTemplateId = $secret.secretTemplateId
            folderId = $secret.folderId
            items = $secret.items
            siteId = $secret.siteId
        } | ConvertTo-Json -Depth 10

        # Update the secret
        try {
            $updateResponse = Invoke-RestMethod -Uri "$baseUrl/api/v1/secrets/$secretId" -Headers $headers -Method Put -Body $updatedSecretBody -ContentType "application/json"
            Write-Log "Updated secret ID $secretId (Name: $secretName) with new $FieldName value '$NewValue'."
            $global:updatedSecretsCount++
        } catch {
            Write-Log "Failed to update secret with ID $secretId (Name: $secretName): $_"
        }
    }
}

# Retrieve all secrets
try {
    $secrets = Invoke-RestMethod -Uri "$baseUrl/api/v1/secrets" -Headers $headers -Method Get
    Write-Log "Retrieved all secrets with a field of $FieldName and a value of $SearchFieldValue."
} catch {
    Write-Log "Failed to retrieve secrets: $_"
    exit
}

# Iterate through all secrets and update the ones that match the criteria
foreach ($secret in $secrets.records) {
    Update-Secret -secretId $secret.id
}

if ($updatedSecretsCount -gt 0) {
    Write-Log "Completed updating secrets. Total secrets modified: $updatedSecretsCount."
} else {
    Write-Log "No secrets updated."
}
