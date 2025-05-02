# --- CONFIGURATION ---
# Define script parameters and configuration variables
param (
    [switch]$Interactive # Enables interactive mode for authentication
)

$BaseUrl                = "https://YOURURL.secretservercloud.com" # Base URL for Secret Server
$OauthUrl               = "$BaseUrl/oauth2/token"                # OAuth token endpoint
$ExcludedTicketSystemId = 3                                      # Ticket system ID to exclude from approval
$ApprovalReason         = "Approved via automation process"      # Reason for approval
$MaxAllowedMinutes      = 60                                     # Maximum allowed duration for approval
$PageSize               = 100                                    # Number of records to fetch per API call
$EnableLogging          = $true                                  # Enable or disable logging
$EnableDebug            = $false                                 # Enable or disable debug output
$LogFilePath            = "C:\Temp\AccessApprovalLog.txt"        # Path to log file
$SdkProfilePath         = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Config" # Path to SDK profile for authentication

# --- LOGGING FUNCTIONS ---
# Functions for logging information and errors
function Log {
    param([string]$Message)
    # Log informational messages with timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [INFO] $Message"
    if ($EnableLogging) { Add-Content -Path $LogFilePath -Value $entry }
    if ($EnableDebug)   { Write-Host "[DEBUG] $entry" }
}

function LogError {
    param([string]$Message)
    # Log error messages with timestamp
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [ERROR] $Message"
    if ($EnableLogging) { Add-Content -Path $LogFilePath -Value $entry }
    Write-Warning $entry
}

# --- AUTHENTICATION FUNCTIONS ---
# Functions for authenticating with Secret Server
function Connect-SecretServer {
    param (
        [string]$SecretServerUrl, # Secret Server base URL
        [string]$OauthUrl         # OAuth token endpoint
    )

    Write-Host "🔐 Connecting to Secret Server..." -ForegroundColor Yellow
    $creds = Get-Credential # Prompt user for credentials
    $Username = $creds.UserName
    $Password = $creds.GetNetworkCredential().Password

    $Body = @{
        grant_type = "password"
        username   = $Username
        password   = $Password
    }

    try {
        # Request OAuth token
        $AuthResponse = Invoke-RestMethod -Uri $OauthUrl -Method POST -Body $Body -ContentType "application/x-www-form-urlencoded"
        $Global:AccessToken = $AuthResponse.access_token

        if (-not $Global:AccessToken) {
            throw "No access_token returned. Check credentials."
        }

        Log "Authentication Successful for user: $Username"
        Write-Host "✅ Authentication Successful" -ForegroundColor Green

    } catch {
        # Handle authentication errors
        LogError "Authentication Failed for user: $Username - $($_.Exception.Message)"
        Write-Host "❌ Authentication Failed" -ForegroundColor Red
        exit 1
    }
}

function Connect-Sdk {
    try {
        # Authenticate using SDK profile
        $token = tss token -cd $SdkProfilePath
        if (-not $token) {
            throw "No token returned from SDK command."
        }
        $global:AccessToken = $token
        Log "Authenticated using SDK token from profile path."
    } catch {
        # Handle SDK authentication errors
        LogError "SDK authentication failed: $_"
        throw
    }
}

# --- AUTHENTICATE ---
# Authenticate based on mode (interactive or SDK)
try {
    if ($Interactive) {
        Connect-SecretServer -SecretServerUrl $BaseUrl -OauthUrl $OauthUrl
    } else {
        Connect-Sdk
    }
} catch {
    LogError "Authentication failed: $_"
    return
}

# --- HEADERS ---
# Prepare headers for API requests
$headers = @{ Authorization = "Bearer $global:AccessToken" }

# --- MAIN PROCESS ---
# Start the approval process
$startTime = Get-Date
Log "==== Access Approval Run Started ===="

# Initialize counters
$approvedCount = 0
$skippedCount  = 0
$failedCount   = 0
$skip          = 0
$morePages     = $true

while ($morePages) {
    # Construct API URI for fetching pending requests
    $pendingUri = "$BaseUrl/api/v1/secret-access-requests?filter.status=Pending&filter.isMyRequest=false&take=$PageSize&skip=$skip"
    Log "Calling URI: $pendingUri"

    try {
        # Fetch pending requests
        $response = Invoke-RestMethod -Uri $pendingUri -Headers $headers -Method Get -ErrorAction Stop
    } catch {
        # Handle errors during API call
        LogError "Failed to retrieve pending requests: $($_.Exception.Message)"
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            LogError "Raw API error body: $($_.ErrorDetails.Message)"
        }
        break
    }

    if (-not $response.records -or $response.records.Count -eq 0) {
        # Exit loop if no pending requests are found
        Log "No pending access requests found in this page."
        break
    }

    foreach ($request in $response.records) {
        # Process each pending request
        $reqId              = $request.secretAccessRequestId
        $ticketSystemId     = $request.ticketSystemId
        $requestedMins      = ([datetime]$request.expirationDate - [datetime]$request.startDate).TotalMinutes

        # Skip requests with excluded ticket system ID
        if ($ticketSystemId -eq $ExcludedTicketSystemId) {
            Log "Skipping request ID $reqId with excluded TicketSystemId $ticketSystemId"
            $skippedCount++
            continue
        }

        # Skip requests exceeding maximum allowed duration
        if ($requestedMins -gt $MaxAllowedMinutes) {
            Log "Skipping request ID $reqId due to excessive requested duration ($requestedMins mins > allowed $MaxAllowedMinutes mins)"
            $skippedCount++
            continue
        }

        # Approve the request
        $approveUri = "$BaseUrl/api/v1/secret-access-requests"
        $payload = @{
            secretAccessRequestId = $reqId
            status                = "Approved"
            startDate             = $request.startDate
            expirationDate        = $request.expirationDate
            responseComment       = $ApprovalReason
        }

        Log "Attempting approval for request ID $reqId"

        try {
            # Send approval request
            Invoke-RestMethod -Uri $approveUri -Headers $headers -Method Put -Body ($payload | ConvertTo-Json -Depth 2) -ContentType "application/json"
            Log "Approved request ID ${reqId} for duration $requestedMins mins"
            $approvedCount++
        } catch {
            # Handle approval errors
            LogError "Approval failed for request ID ${reqId}: $($_.Exception.Message)"
            if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                LogError "Raw API error body: $($_.ErrorDetails.Message)"
            }
            $failedCount++
            continue
        }
    }

    # Check if more pages are available
    $morePages = $response.hasNext
    $skip += $PageSize
}

# --- SUMMARY ---
# Log summary and execution time
$endTime   = Get-Date
$elapsed   = $endTime - $startTime
$formatted = '{0:hh\:mm\:ss}' -f $elapsed

Log "Run Summary: Approved=$approvedCount, Skipped=$skippedCount, Failed=$failedCount"
Log "Total execution time: $formatted"
Log "==== Access Approval Run Complete ===="
