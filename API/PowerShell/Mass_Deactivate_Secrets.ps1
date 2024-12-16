<#
.SYNOPSIS
This script deactivates secrets in Secret Server based on data from a CSV file.

.DESCRIPTION
The script performs the following steps:
1. Prompts the user for credentials to authenticate with Secret Server.
2. Requests an OAuth2 access token using the provided credentials.
3. Imports a CSV file containing secret information.
4. Iterates through each row in the CSV and deactivates the corresponding secret in Secret Server.
5. Logs the results of each operation to a specified log file.

.PARAMETER $csvPath
The file path to the CSV file containing secret information. The CSV should have columns: SecretID, Folderpath, and SecretName.

.PARAMETER $logFilePath
The file path where the log file will be saved.

.PARAMETER $baseUrl
The base URL for the Secret Server instance.

.PARAMETER $tokenUrl
The OAuth2 token endpoint URL for Secret Server.

.PARAMETER $deleteSecretEndpoint
The API endpoint URL for deleting secrets in Secret Server.

.EXAMPLE
.\Deactivate-Secrets.ps1
Prompts for credentials, imports secrets from the specified CSV file, deactivates them in Secret Server, and logs the results.

.NOTES
- Ensure the CSV file exists at the specified path.
- The script requires the user to have appropriate permissions to deactivate secrets in Secret Server.
- The log file will be created or cleared if it already exists.

#>
# ============================
# Variables
# ============================
# File paths
$csvPath = "C:\Path\To\Your\File.csv"  # Replace with your actual CSV file path
$logFilePath = "C:\Path\To\LogFile.log"  # Replace with your desired log file location

# Secret Server API
$baseUrl = "https://XXXXXX.secretservercloud.com"  # Base URL for your Secret Server
$tokenUrl = "$baseUrl/oauth2/token"  # OAuth2 token endpoint
$deleteSecretEndpoint = "$baseUrl/api/v1/secrets"  # Endpoint to delete secrets

# ============================
# Authentication
# ============================
# Prompt for Credentials
$cred = Get-Credential

# Extract Username and Password
$username = $cred.UserName
$password = $cred.GetNetworkCredential().Password

# Prepare the Body for Token Request
$body = @{
    grant_type = "password"
    username   = $username
    password   = $password
}

# Request Access Token
$response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"

# Extract Access Token
$accessToken = $response.access_token

# Validate and Display Token
if ($accessToken) {
    Write-Host "Authentication successful! Access Token retrieved." -ForegroundColor Green
} else {
    Write-Host "Authentication failed. Please check your credentials." -ForegroundColor Red
    return
}

# Set Authorization Headers
$headers = @{
    Authorization = "Bearer $accessToken"
}

# ============================
# Import and Process CSV
# ============================
# Check and Load CSV
if (-Not (Test-Path -Path $csvPath)) {
    Write-Host "CSV file not found at path: $csvPath" -ForegroundColor Red
    return
}

Write-Host "Importing CSV from: $csvPath" -ForegroundColor Cyan
$data = Import-Csv -Path $csvPath

if (-Not $data) {
    Write-Host "CSV is empty or could not be loaded." -ForegroundColor Red
    return
}

Write-Host "CSV successfully loaded. Processing rows..." -ForegroundColor Green

# Initialize Log File
if (-Not (Test-Path -Path $logFilePath)) {
    New-Item -ItemType File -Path $logFilePath -Force | Out-Null
} else {
    Clear-Content -Path $logFilePath
}

# Function to Log Messages
function Write-Message {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $logFilePath -Value $logEntry
    Write-Host $Message
}

# ============================
# Deactivate Secrets
# ============================
foreach ($row in $data) {
    # Extract Values
    $secretID = $row.SecretID
    $folderPath = $row.Folderpath
    $secretName = $row.SecretName

    # Log the current secret being processed
    Write-Message "Processing SecretID: $secretID, Folderpath: $folderPath, SecretName: $secretName"

    try {
        # API Call to Deactivate (Delete) Secret
        $deactivateUrl = "$deleteSecretEndpoint/$secretID"
        Invoke-RestMethod -Method Delete -Uri $deactivateUrl -Headers $headers

        # Log successful deactivation
        Write-Message "Successfully deactivated SecretID: $secretID"
    } catch {
        # Log any errors
        $errorMessage = $_.Exception.Message
        Write-Message "Error deactivating SecretID: $secretID. Error: $errorMessage" -ForegroundColor Red
    }
}

# Final Completion Message
Write-Message "All secrets have been processed."
Write-Host "Script completed. Logs saved at: $logFilePath" -ForegroundColor Green