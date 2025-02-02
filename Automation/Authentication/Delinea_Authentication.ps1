# ===============================
# Secret Server SDK & OAuth Authentication Script
# ===============================

# === Variables (Always at the Top) ===
$SecretServerUrl = "https://yoururl.secretservercloud.com"  # Adjust to match your instance
$SdkPath = "C:\Path\To\SDK"                             # Adjust this to the actual SDK path
$ConfigDirectory = "C:\tss"                             # Configuration directory for the SDK
$LogPath = "C:\Logs\SecretServerSDK.log"                # Log file path (ensure the directory exists)
$ClientId = "your_client_id"                            # OAuth client ID (if needed)
$ClientSecret = "your_client_secret"                    # OAuth client secret (if needed)
$global:AuthToken = $null
$global:RefreshToken = $null

# === Function: Write to Log File ===
function Write-Log {
    param (
        [string]$Message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $Message"
    Add-Content -Path $LogPath -Value $logEntry
}

# === Function: Authenticate via SDK (Secret Server CLI) ===
function Auth-SDK {
    try {
        Write-Host "Authenticating via Secret Server SDK..." -ForegroundColor Cyan
        Write-Log "Starting SDK authentication process."

        # Construct the command and argument list for SDK authentication
        $cmd = "$SdkPath\tss.exe"
        $cmdArgList = @(
            "-cd", $ConfigDirectory  # Specify the SDK configuration directory
            "token"                  # Request an authentication token
        )

        # Execute the command and capture the output
        $response = & $cmd @cmdArgList

        if ($response) {
            # Extract Access and Refresh Tokens
            $responseData = $response | ConvertFrom-Json
            $global:AuthToken = $responseData.access_token
            $global:RefreshToken = $responseData.refresh_token

            Write-Host "SDK Authentication successful. Token stored globally." -ForegroundColor Green
            Write-Log "SDK Authentication successful. Token retrieved."
        } else {
            Write-Error "SDK Authentication failed - No token received."
            Write-Log "ERROR: SDK Authentication failed."
        }
    } catch {
        Write-Error "An error occurred during SDK authentication: $_"
        Write-Log "ERROR: Exception occurred during SDK authentication - $_"
    }
}

# === Function: Authenticate via OAuth (Refresh Token Flow) ===
function Auth-OAuth {
    try {
        if (-not $global:RefreshToken) {
            Write-Host "No refresh token available. Re-authentication required." -ForegroundColor Yellow
            Write-Log "WARNING: No refresh token found. Re-authentication needed."
            return $null
        }

        Write-Host "Refreshing access token via OAuth..." -ForegroundColor Cyan
        Write-Log "Attempting to refresh OAuth access token."

        $authEndpoint = "$SecretServerUrl/oauth2/token"
        $body = @{
            grant_type    = "refresh_token"
            client_id     = $ClientId
            client_secret = $ClientSecret
            refresh_token = $global:RefreshToken
        }

        # Request a new access token
        $response = Invoke-RestMethod -Uri $authEndpoint -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

        if ($response.access_token -and $response.refresh_token) {
            # Store the new tokens securely
            $global:AuthToken = $response.access_token
            $global:RefreshToken = $response.refresh_token

            Write-Host "OAuth Token refreshed successfully." -ForegroundColor Green
            Write-Log "OAuth Token refreshed successfully."
        } else {
            Write-Error "Failed to refresh OAuth token."
            Write-Log "ERROR: OAuth token refresh failed."
            return $null
        }
    } catch {
        Write-Error "Error during OAuth token refresh: $_"
        Write-Log "ERROR: Exception occurred during OAuth token refresh - $_"
        return $null
    }
}

# === Function: Retrieve Stored Token (Refresh If Needed) ===
function Get-Token {
    if (-not $global:AuthToken) {
        Write-Host "No valid token found. Trying to refresh OAuth token..." -ForegroundColor Yellow
        Write-Log "WARNING: No valid token found. Attempting refresh."
        Auth-OAuth
    }
    
    if (-not $global:AuthToken) {
        Write-Host "Token refresh failed. Please authenticate via SDK." -ForegroundColor Red
        Write-Log "ERROR: OAuth token refresh failed. Switching to SDK authentication."
        Auth-SDK
    }

    return $global:AuthToken
}

# === Function: Ensure a Valid Token Exists (Refresh or Re-authenticate if Needed) ===
function Ensure-Token {
    $token = Get-Token
    if (-not $token) {
        Write-Host "Authentication required. Attempting SDK authentication..." -ForegroundColor Yellow
        Write-Log "No valid token. Running SDK authentication."
        Auth-SDK
    }
}

# === Script Execution ===
Ensure-Token

# Example API Call Using the Token (With Refresh Handling)
$token = Get-Token
if ($token) {
    $headers = @{ Authorization = "Bearer $token" }
    Write-Host "Token ready for API calls." -ForegroundColor Cyan
    Write-Log "Token is ready for API calls."
} else {
    Write-Error "Token is missing. Cannot proceed with API calls."
    Write-Log "ERROR: No valid token found for API calls."
}
