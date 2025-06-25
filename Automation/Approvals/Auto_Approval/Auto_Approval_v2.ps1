# --- CONFIGURATION ---
param (
    [switch]$Interactive
)

$BaseUrl                = "https://YOURURL.secretservercloud.com"
$OauthUrl               = "$BaseUrl/oauth2/token"
$ExcludedTicketSystemId = 3
$ApprovalReason         = "Approved via automation process"
$MaxAllowedMinutes      = 60
$PageSize               = 100
$EnableLogging          = $true
$EnableDebug            = $false
$LogFilePath            = "C:\Temp\AccessApprovalLog.txt"
$SdkProfilePath         = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Config" # Path to SDK profile for authentication
$SdkKeypath             = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Key"  # Path to SDK profile for authentication
$script:AccessToken     = $null

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
        [string]$SecretServerUrl,
        [string]$OauthUrl
    )

    Write-Host " Connecting to Secret Server..." -ForegroundColor Yellow
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
        $script:AccessToken = $AuthResponse.access_token

        if (-not $script:AccessToken) {
            throw "No access_token returned. Check credentials."
        }

        Log "Authentication Successful for user: $Username"
        Write-Host " Authentication Successful" -ForegroundColor Green

    } catch {
        LogError "Authentication Failed for user: $Username - $($_.Exception.Message)"
        Write-Host " Authentication Failed" -ForegroundColor Red
        exit 1
    }
}

function Connect-Sdk {
    try {
        $token = tss token -cd $SdkProfilePath -kd $SdkKeypath
        if (-not $token) { throw "No token returned from SDK command." }
        $script:AccessToken = $token
        Log "Authenticated using SDK token from profile path."
    } catch {
        LogError "SDK authentication failed: $_"
        throw
    }
}

# --- Check Already Approved ---
function Test-IfAlreadyApproved {
    param (
        [int]$RequestId,
        [int]$SecretId,
        [string]$TicketNumber,
        [int]$UserId,
        [hashtable]$Headers,
        [string]$BaseUrl
    )

    $pageSize = 100
    $skip = 0
    $matched = $false
    $today = (Get-Date).ToString("yyyy-MM-ddT00:00:00")

    Log "Checking if request ID $RequestId was already approved (paged, filtered by today $today)..."

    do {
        $uri = "$BaseUrl/api/v1/secret-access-requests?filter.isMyRequest=true&filter.status=Approved&filter.startDateMin=$today&take=$pageSize&skip=$skip&sortBy[0].direction=desc&sortBy[0].name=startDate"

        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $Headers -Method Get -ErrorAction Stop

            if ($response.records) {
                foreach ($record in $response.records) {
                    if (
                        $record.secretAccessRequestId -eq $RequestId -or
                        ($record.secretId -eq $SecretId -and $record.ticketNumber -eq $TicketNumber -and $record.requestingUserId -eq $UserId)
                    ) {
                        $matched = $true
                        break
                    }
                }
            }

            if ($matched) {
                Log "Request ID $RequestId was already approved by another node."
                return $true
            }

            $skip += $pageSize
        } catch {
            LogError "Error while paging through today's approved requests for ID $RequestId : $($_.Exception.Message)"
            return $false
        }
    } while ($response.hasNext)

    Log "Request ID $RequestId not found in today's approved list."
    return $false
}

# --- AUTHENTICATE ---
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

$headers = @{ Authorization = "Bearer $script:AccessToken" }

# --- MAIN PROCESS ---
$startTime = Get-Date
Log "==== Access Approval Run Started ===="

$approvedCount = 0
$skippedCount  = 0
$alreadyCount  = 0
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
        $reqId          = $request.secretAccessRequestId
        $ticketSystemId = $request.ticketSystemId
        $requestedMins  = ([datetime]$request.expirationDate - [datetime]$request.startDate).TotalMinutes

        if ($ticketSystemId -eq $ExcludedTicketSystemId) {
            Log "Skipping request ID $reqId with excluded TicketSystemId $ticketSystemId"
            $skippedCount++
            continue
        }

        if ($requestedMins -gt $MaxAllowedMinutes) {
            Log "Skipping request ID $reqId due to excessive requested duration ($requestedMins mins > allowed $MaxAllowedMinutes mins)"
            $skippedCount++
            continue
        }

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
            Invoke-RestMethod -Uri $approveUri -Headers $headers -Method Put -Body ($payload | ConvertTo-Json -Depth 2) -ContentType "application/json"
            Log "Approved request ID $reqId for duration $requestedMins mins"
            $approvedCount++
        } catch {
            LogError "Approval failed for request ID $reqId : $($_.Exception.Message)"
            if ($_.ErrorDetails -and $_.ErrorDetails.Message) {
                LogError "Raw API error body: $($_.ErrorDetails.Message)"
            }

            $alreadyApproved = Test-IfAlreadyApproved -RequestId $reqId `
                                                      -SecretId $request.secretId `
                                                      -TicketNumber $request.ticketNumber `
                                                      -UserId $request.requestingUserId `
                                                      -Headers $headers `
                                                      -BaseUrl $BaseUrl

            if ($alreadyApproved) {
                Log "Skipping failure count. Request $reqId already approved."
                $alreadyCount++
            } else {
                $failedCount++
            }

            continue
        }
    }

    $morePages = $response.hasNext
    $skip += $PageSize
}

# --- SUMMARY ---
$endTime   = Get-Date
$elapsed   = $endTime - $startTime
$formatted = '{0:hh\:mm\:ss}' -f $elapsed

Log "Run Summary: Approved=$approvedCount, Skipped=$skippedCount, AlreadyApproved=$alreadyCount, Failed=$failedCount"
Log "Total execution time: $formatted"
Log "==== Access Approval Run Complete ===="