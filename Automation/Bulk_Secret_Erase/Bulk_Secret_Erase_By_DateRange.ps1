<#
.SYNOPSIS
    This PowerShell script automates the process of exporting a report of secrets and submitting a bulk request to erase those secrets using the Secret Server API.

.DESCRIPTION
    The script performs the following tasks:
    1. Authenticates with Secret Server to obtain an access token using OAuth2.
    2. Exports a specified report of secrets to a CSV file for backup and analysis.
    3. Extracts secret IDs from the exported report.
    4. Sends a bulk request to erase the identified secrets after a specified delay. Request are done by the user executing the script

.FEATURES
    - Authentication: Prompts the user for Secret Server credentials and retrieves an access token for API interactions.
    - Report Export: Exports a specified report of secrets to a CSV file located at `C:\temp\Secret_erase\report.csv`.
    - Secret Erasure: Extracts secret IDs from the exported CSV file and submits a bulk erase request for the identified secrets.
    - Completion Notification: Outputs messages indicating the status of each operation and a final message upon script completion.

.COMPONENTS
    Variables:
        - $apiBaseUri: Base URI for API endpoints.
        - $reportExportEndpoint: URI for exporting the report.
        - $eraseEndpoint: URI for sending the bulk erase request.
        - $authEndpoint: URI for obtaining the OAuth2 token.
        - $reportId: ID of the report to be exported.
        - $requestComment: Comment associated with the erase request.
        - $eraseAfter: Date set to 48 hours in the future.
        - $outputDirectory and $outputPath: Locations for saving the exported CSV file.
    
    Functions:
        - New-Session: Authenticates with Secret Server and retrieves an access token.
        - Export-Report: Exports a specified report to a CSV file.
        - Send-BulkSecretEraseRequest: Sends a bulk erase request for the extracted secret IDs.
    
    Main Execution Flow:
        - Establishes a session and retrieves an access token.
        - Exports the report to a specified file and extracts secret IDs.
        - Sends a bulk erase request for the extracted secrets.
        - Outputs completion messages for each operation.

.USAGE
    1. **Run the Entire Script**:
       - Execute the script from PowerShell:
         ```powershell
         .\YourScriptName.ps1
         ```

    2. **Dot-Source and Run Individual Functions**:
       - Load functions into the current session:
         ```powershell
         . .\YourScriptName.ps1
         ```

    3. **Establish a Session**:
       - Run the `New-Session` function to authenticate and get an access token:
         ```powershell
         $authToken = New-Session -SecretServerURL "https://XXXX.secretservercloud.com/oauth2/token"
         ```

    4. **Export a Report**:
       - Run the `Export-Report` function to export the report:
         ```powershell
         Export-Report -reportId "217" -authToken $authToken -outputPath "C:\temp\Secret_erase\report.csv"
         ```

    5. **Send a Bulk Erase Request**:
       - Run the `Send-BulkSecretEraseRequest` function with a list of secret IDs:
         ```powershell
         $secretIds = @("123", "456", "789")  # Example secret IDs
         Send-BulkSecretEraseRequest -secretIds $secretIds -authToken $authToken -requestComment "Erase old secrets" -eraseAfter (Get-Date).AddHours(48).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
         ```

.PREREQUISITES
    - PowerShell: Ensure PowerShell is installed and configured on the system.
    - API Access: Valid credentials and appropriate permissions for Secret Server API access are required.
    - Network Access: 443 access to SS URL
    - Secret erase workflow setup
    - User executing this is used for the erase request/comment/date of erase.
    - User must have the following rights on the secret to perform the operation.
        * Is inactive
        * Is owned by you
        * Does not have a pending secret erase request
        * Is not double-locked
        * Is not checked out by another user
        * Is not a discovery secret
        * Is not a domain sync secret
#>

# Variables
$apiBaseUri = "https://XXXXX.secretservercloud.com/api/v1"
$reportExportEndpoint = "$apiBaseUri/reports/export"
$eraseEndpoint = "$apiBaseUri/secret-erase-requests"
$authEndpoint = "https://XXXXX.secretservercloud.com/oauth2/token"
$reportId = "217"
$requestComment = "Request to erase secrets older than 365 days"
$eraseAfter = (Get-Date).AddHours(48).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")  # Erase after 48 hours in UTC
$outputDirectory = "C:\temp\Secret_erase"
$outputPath = Join-Path -Path $outputDirectory -ChildPath "report.csv"

# Ensure the directory exists
if (-not (Test-Path -Path $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory -Force
}

# Establish a new session with the Secret Server
function New-Session {
    param (
        [string]$SecretServerURL
    )

    try {
        # Debug: Print the auth endpoint URL
        Write-Host "Auth Endpoint URL: $SecretServerURL"

        # Prompt user for credentials
        $cred = Get-Credential
        
        # Prepare the body for the OAuth2 token request
        $body = @{
            grant_type = "password"
            username   = $cred.UserName
            password   = $cred.GetNetworkCredential().Password
        }

        # Make the OAuth2 token request
        $response = Invoke-RestMethod -Uri $SecretServerURL -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

        # Check if the response contains an access token
        if ($response -and $response.access_token) {
            Write-Host "Session established successfully." -ForegroundColor Green
            return $response.access_token
        } else {
            Write-Host "Failed to establish a session with the Secret Server." -ForegroundColor Red
            return $null
        }
    } catch {
        Write-Host "An error occurred while trying to establish a session: $_" -ForegroundColor Red
        return $null
    }
}

# Export the report containing secrets to be erased - Hold on to backup file as the secretnames will be randomized post erase. You can match on ID
function Export-Report {
    param (
        [string]$reportId,
        [string]$authToken,
        [string]$outputPath
    )
    $headers = @{
        "Authorization" = "Bearer $authToken"
        "Content-Type" = "application/json"
    }

    # Construct the body payload for the export request
    $body = @{
        delimiter = ","
        encodeHtml = $false
        format = "CSV"
        id = [int]$reportId
        useDefaultParameters = $true
    } | ConvertTo-Json

    # Use the export endpoint directly
    $reportUrl = $reportExportEndpoint

    # Debug: Print the report export endpoint URL
    Write-Host "Report Export Endpoint URL: $reportUrl"

    try {
        # Use POST method to request report export
        Invoke-RestMethod -Uri $reportUrl -Method Post -Headers $headers -Body $body -OutFile $outputPath
        return $true
    } catch {
        Write-Error "Failed to export report: $_"
        return $false
    }
}

# Submit bulk Secret Erase Request
function Send-BulkSecretEraseRequest {
    param (
        [array]$secretIds,
        [string]$authToken,
        [string]$requestComment,
        [string]$eraseAfter
    )
    $headers = @{
        "Authorization" = "Bearer $authToken"
        "Content-Type" = "application/json"
    }
    $body = @{
        eraseAfter = $eraseAfter
        requestComment = $requestComment
        secretIds = $secretIds
    } | ConvertTo-Json

    # Debug: Print the erase endpoint URL
    Write-Host "Erase Endpoint URL: $eraseEndpoint"

    try {
        $response = Invoke-RestMethod -Uri $eraseEndpoint -Method Post -Headers $headers -Body $body
        return $response
    } catch {
        Write-Error "Failed to send bulk erase request: $_"
        return $null
    }
}

# Main script execution
# Step 1: Establish a session with the Secret Server
$authToken = New-Session -SecretServerURL $authEndpoint
if (-not $authToken) {
    Write-Error "Unable to establish session. Exiting script."
    exit
}

# Step 2: Export the report
if (Export-Report -reportId $reportId -authToken $authToken -outputPath $outputPath) {
    Write-Output "Report successfully exported to $outputPath"
} else {
    Write-Error "Report data could not be retrieved. Exiting script."
    exit
}

# Step 3: Read the exported report and extract Secret IDs
$csvData = Import-Csv -Path $outputPath
$secretIds = $csvData | ForEach-Object { $_.SecretId }

# Step 4: Send Bulk Secret Erase Request
if ($secretIds.Count -gt 0) {
    $bulkEraseResponse = Send-BulkSecretEraseRequest -secretIds $secretIds -authToken $authToken -requestComment $requestComment -eraseAfter $eraseAfter
    if ($bulkEraseResponse) {
        Write-Output "Bulk erase request successfully sent for Secrets"
    } else {
        Write-Error "Failed to process bulk erase request."
    }
} else {
    Write-Output "No secrets found for deletion."
}

Write-Output "Script execution completed."
