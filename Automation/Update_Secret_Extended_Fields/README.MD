Update Secret Field
A PowerShell script to update secret fields in Secret Server based on specified criteria.

Description
This script authenticates with Secret Server, retrieves all secrets, and updates the specified field with a new value for secrets that match the given criteria.

Parameters
SearchFieldValue (string): The value to search for in the specified field. Default is "abc.local".
FieldName (string): The name of the field to search and update. Default is "Domain".
NewValue (string): The new value to set in the specified field. Default is "happy.local".
OtpCode (string): The OTP code for authentication if the UseOtp switch is used.
UseOtp (switch): Switch to use OTP for authentication.
Usage
Run the script with the necessary parameters:

Example 1: Update Domain Field
powershell
Copy code
.\UpdateSecretField.ps1 -SearchFieldValue "abc.local" -FieldName "Domain" -NewValue "happy.local"
Example 2: Update Username Field
powershell
Copy code
.\UpdateSecretField.ps1 -SearchFieldValue "olduser" -FieldName "Username" -NewValue "newuser"
Example 3: Update Email Field
powershell
Copy code
.\UpdateSecretField.ps1 -SearchFieldValue "oldemail@example.com" -FieldName "Email" -NewValue "newemail@example.com"
Example 4: Using OTP for Authentication
powershell
Copy code
.\UpdateSecretField.ps1 -SearchFieldValue "abc.local" -FieldName "Domain" -NewValue "happy.local" -OtpCode "123456" -UseOtp
Script Details
Parameters
SearchFieldValue (string): The value to search for in the specified field. Default is "abc.local".
FieldName (string): The name of the field to search and update. Default is "Domain".
NewValue (string): The new value to set in the specified field. Default is "happy.local".
OtpCode (string): The OTP code for authentication if the UseOtp switch is used.
UseOtp (switch): Switch to use OTP for authentication.
Log File
The script generates a log file in C:\temp with the name Update_Secret_Field_<FieldName>_<timestamp>.txt.

Authentication
The script supports two methods of authentication:

Username and Password: The script prompts for credentials.
OTP: The script uses the provided OTP code for authentication if the UseOtp switch is used.
Functions
Write-Log
Writes log messages to a file and the host.

powershell
Copy code
function Write-Log {
    param (
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp - $message"
    Add-Content -Path $LogFilePath -Value $logMessage
    Write-Host $logMessage
}
Update-Secret
Updates a secret if it has the specified field with the specified value.

powershell
Copy code
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

    $fieldToUpdate = $secret.items | Where-Object { $_.fieldName -eq $FieldName -and $_.itemValue -eq $SearchFieldValue }

    if ($fieldToUpdate) {
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
