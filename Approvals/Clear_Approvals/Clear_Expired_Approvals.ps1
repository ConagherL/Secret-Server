# --- CONFIGURATION ---
# Define script parameters and configuration variables
$Interactive            = $true                                # Set to $true for interactive auth, $false for SDK auth
$BaseUrl                = "https://YOURSSURL" # Base URL for Secret Server
$OauthUrl               = "$BaseUrl/oauth2/token"                # OAuth token endpoint
$ExcludedTicketSystemId = $null                                     # Ticket system ID to exclude from processing
$DeclineReason          = "Auto-declined: Request expired"       # Reason for auto-decline
$ExpiredDeclineBuffer   = 60                                    # Minutes past expiration before auto-declining (configurable)
$PageSize               = 100                                    # Number of records to fetch per API call
$EnableLogging          = $true                                  # Enable or disable logging
$EnableDebug            = $false                                 # Enable or disable debug output
$LogFilePath            = "C:\Temp\ExpiredAccessDeclineLog.txt"  # Path to log file
$SdkProfilePath         = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Config" # Path to SDK profile for authentication
$SdkKeypath             = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Key"  # Path to SDK profile for authentication

# --- LOGGING FUNCTIONS ---
function Log {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [INFO] $Message"
    if ($EnableLogging) { Add-Content -Path $LogFilePath -Value $entry }
    if ($EnableDebug)   { Write-Host "[DEBUG] $entry" }
}

function LogError {
    param([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "$timestamp [ERROR] $Message"
    if ($EnableLogging) { Add-Content -Path $LogFilePath -Value $entry }
    Write-Warning $entry
}

# --- AUTHENTICATION FUNCTIONS ---
function Connect-SecretServer {
    param (
        [string]$SecretServerUrl, # Secret Server base URL
        [string]$OauthUrl         # OAuth token endpoint
    )

    Write-Host "Connecting to Secret Server..." -ForegroundColor Yellow
    $creds = Get-Credential
    $Username = $creds.UserName
    $Password = $creds.GetNetworkCredential().Password

    $Body = @{
        grant_type = "password"
        username   = $Username
        password   = $Password
    }

    try {
        $AuthResponse = Invoke-RestMethod -Uri $OauthUrl -Method POST -Body $Body -ContentType "application/x-www-form-urlencoded"
        $Global:AccessToken = $AuthResponse.access_token

        if (-not $Global:AccessToken) {
            throw "No access_token returned. Check credentials."
        }

        Log "Authentication Successful for user: $Username"
        Write-Host "Authentication Successful" -ForegroundColor Green

    } catch {
        LogError "Authentication Failed for user: $Username - $($_.Exception.Message)"
        Write-Host "Authentication Failed" -ForegroundColor Red
        exit 1
    }
}

function Connect-Sdk {
    try {
        $token = tss token -cd $SdkProfilePath -kd $SdkKeypath
        if (-not $token) {
            throw "No token returned from SDK command."
        }
        $global:AccessToken = $token
        Log "Authenticated using SDK token from profile path."
    } catch {
        LogError "SDK authentication failed: $_"
        throw
    }
}

# --- UTILITY FUNCTIONS ---
function Test-RequestExpired {
    param([datetime]$ExpirationDate)
    
    $currentTime = Get-Date
    $bufferTime = $currentTime.AddMinutes(-$ExpiredDeclineBuffer)
    
    # Request is considered expired if it's past the expiration date + buffer time
    return $ExpirationDate -lt $bufferTime
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
$headers = @{ Authorization = "Bearer $global:AccessToken" }

# --- MAIN PROCESS ---
$startTime = Get-Date
Log "==== Expired Access Request Decline Run Started ===="
Log "Configuration: ExpiredDeclineBuffer=$ExpiredDeclineBuffer minutes"

# Counters for declined, skipped, and failed requests
$declinedCount = 0
$skippedCount  = 0
$failedCount   = 0
$skip          = 0
$morePages     = $true

while ($morePages) {
    $pendingUri = "$BaseUrl/api/v1/secret-access-requests?filter.status=Pending&filter.isMyRequest=false&take=$PageSize&skip=$skip"
    Log "Calling URI: $pendingUri"

    try {
        $response = Invoke-RestMethod -Uri $pendingUri -Headers $headers -Method Get -ErrorAction Stop
    } catch {
        LogError "Failed to retrieve pending requests: $($_.Exception.Message)"
        if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
            LogError "Raw API error body: $($_.ErrorDetails.Message)"
        }
        break
    }

    if (-not $response.records -or $response.records.Count -eq 0) {
        Log "No pending access requests found in this page."
        break
    }

    foreach ($request in $response.records) {
        $reqId              = $request.secretAccessRequestId
        $ticketSystemId     = $request.ticketSystemId
        # Convert UTC time from API to local time for proper comparison
        $expirationDateUTC  = [datetime]::Parse($request.expirationDate, $null, [System.Globalization.DateTimeStyles]::AssumeUniversal)
        $expirationDate     = $expirationDateUTC.ToLocalTime()
        $requesterName      = $request.requestorDisplayName
        $secretName         = $request.secretName

        Log "Processing request ID $reqId by $requesterName for secret '$secretName' (expires: $expirationDate)"

        # Skip requests with excluded ticket system ID (if configured)
        if ($ExcludedTicketSystemId -and $ticketSystemId -eq $ExcludedTicketSystemId) {
            Log "Skipping request ID $reqId with excluded TicketSystemId $ticketSystemId"
            $skippedCount++
            continue
        }

        # Check if request is expired (past expiration + buffer time)
        if (Test-RequestExpired -ExpirationDate $expirationDate) {
            # Decline the expired request
            $declineUri = "$BaseUrl/api/v1/secret-access-requests"
            $payload = @{
                secretAccessRequestId = $reqId
                status                = "Denied"
                startDate             = $request.startDate
                expirationDate        = $request.expirationDate
                responseComment       = $DeclineReason
            }

            Log "Auto-declining expired request ID $reqId (expired: $expirationDate)"

            try {
                # Send decline request
                [void](Invoke-RestMethod -Uri $declineUri -Headers $headers -Method Put -Body ($payload | ConvertTo-Json -Depth 2) -ContentType "application/json")
                Log "Successfully declined expired request ID $reqId"
                $declinedCount++
            } catch {
                # Handle decline errors
                LogError "Decline failed for request ID $reqId`: $($_.Exception.Message)"
                if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                    LogError "Raw API error body: $($_.ErrorDetails.Message)"
                }
                $failedCount++
                continue
            }
        } else {
            $minutesRemaining = [math]::Round(($expirationDate - (Get-Date)).TotalMinutes, 1)
            if ($minutesRemaining -lt 0) {
                Log "Request ID $reqId expired $([math]::Abs($minutesRemaining)) minutes ago, but within buffer period ($ExpiredDeclineBuffer min), skipping"
            } else {
                Log "Request ID $reqId is not yet expired (expires in $minutesRemaining minutes), skipping"
            }
            $skippedCount++
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

Log "Run Summary: Declined=$declinedCount, Skipped=$skippedCount, Failed=$failedCount"
Log "Total execution time: $formatted"
Log "==== Expired Access Request Decline Run Complete ===="

# Display summary to console
Write-Host "`n=== EXECUTION SUMMARY ===" -ForegroundColor Cyan
Write-Host "Auto-Declined (Expired): $declinedCount" -ForegroundColor Yellow
Write-Host "Skipped (Not Expired): $skippedCount" -ForegroundColor Blue
Write-Host "Failed: $failedCount" -ForegroundColor Red
Write-Host "Execution Time: $formatted" -ForegroundColor Cyan