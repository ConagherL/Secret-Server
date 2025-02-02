<#
.SYNOPSIS
    This script connects to a Secret Server using OAuth2 (via password grant or a pre-obtained token),
    retrieves the current Discovery scan status, logs key details, and initiates a new Discovery scan if no
    scan is currently running or if the last scan's fetch start time is older than a specified wait period.

.DESCRIPTION
    The script performs the following tasks:
      - Connects to a Secret Server by either using a pre-obtained token (non-interactive) or prompting
        for credentials (interactive).
      - Retrieves the Discovery scan status from the Secret Server and logs important fields such as the 
        discovery fetch start time, and whether a discovery fetch or computer scan is currently running.
      - If no scan is running and the last scan's start time is older than the configured wait period, a 
        new Discovery scan is initiated.
      - Logs key events and errors to a configurable log file.

.PARAMETER (None)
    This script is designed to run as-is. For non-interactive runs, supply a token by setting the 
    $preObtainedToken variable. Otherwise, the script will prompt for credentials interactively.

.NOTES
    - For non-interactive use (e.g., scheduled tasks), ensure that a valid pre-obtained token is provided.
    - Modify the global variables ($Global:SecretServerURL, $Global:LogPath, and $Global:DiscoveryWaitPeriodMinutes)
      as needed to suit your environment.
    - Logging can be enabled or disabled using the $Global:LoggingEnabled variable.
#>

###############################################################################
# VARIABLES - Configure These First
###############################################################################
$Global:SecretServerURL = "https://YOURURL.secretservercloud.com"   # Replace with your actual Secret Server URL
$Global:LogPath = "C:\temp\script.log"                          # Update the log file location as needed
$Global:DiscoveryWaitPeriodMinutes = 10                         # Set wait period in minutes (set to blank or 0 to not wait)
$Global:LoggingEnabled = $true                                  # Set to $false to disable logging
$preObtainedToken = ""                                          # Set this to your token if available; otherwise, leave blank to prompt.

# Default wait period to 0 if blank or not defined.
if (-not $Global:DiscoveryWaitPeriodMinutes) {
    $Global:DiscoveryWaitPeriodMinutes = 0
}

###############################################################################
# FUNCTION: Write-Log
# Writes log entries to the file defined by $Global:LogPath if logging is enabled.
###############################################################################
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        [string]$Level = "INFO"
    )
    if (-not $Global:LoggingEnabled) { return }
    $TimeStamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$TimeStamp [$Level] - $Message"
    
    # Ensure the directory exists.
    $logDir = Split-Path -Path $Global:LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }
    
    $logEntry | Out-File -FilePath $Global:LogPath -Append
}

###############################################################################
# FUNCTION: Connect to Secret Server (OAuth2 Password Grant)
# Optional parameter -Token allows non-interactive use with a pre-obtained token.
###############################################################################
function Connect-SecretServer {
    param (
        [string]$SecretServerUrl,
        [string]$Token  # Optional: if provided, use this token instead of prompting for credentials.
    )

    # If a token is supplied, use it.
    if ($Token -and $Token -ne "") {
        $Global:AccessToken = $Token
        Write-Log "Using provided token for authentication." -Level "INFO"
        Write-Host "✅ Using provided authentication token." -ForegroundColor Green
        return $true
    }
    
    # If a token already exists, use it.
    if ($Global:AccessToken -and $Global:AccessToken -ne "") {
        Write-Log "Existing token found. Skipping authentication." -Level "INFO"
        Write-Host "✅ Using existing authentication token." -ForegroundColor Green
        return $true
    }
    
    # Build the OAuth endpoint URL by appending /oauth2/token.
    $OauthUrl = "$SecretServerUrl/oauth2/token"
    
    Write-Host "🔐 Connecting to Secret Server interactively..." -ForegroundColor Yellow
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

        Write-Log "Authentication Successful for user: $Username" -Level "INFO"
        Write-Host "✅ Authentication Successful" -ForegroundColor Green
        return $true
    } catch {
        Write-Log "Authentication Failed for user: $Username - $($_.Exception.Message)" -Level "ERROR"
        Write-Host "❌ Authentication Failed" -ForegroundColor Red
        exit 1
    }
}

###############################################################################
# FUNCTION: Get-TssDiscoveryStatus
# Retrieves the full Discovery scan status response from the Secret Server,
# logs key fields, and returns the status object.
###############################################################################
function Get-TssDiscoveryStatus {
    [CmdletBinding()]
    param ()

    # Construct the Discovery status API endpoint.
    $uri = "$Global:SecretServerURL/api/v1/discovery/status"

    try {
        Write-Verbose "Retrieving Discovery status from: $uri"
        $statusResponse = Invoke-RestMethod -Uri $uri -Method GET -Headers @{ Authorization = "Bearer $Global:AccessToken" } -ContentType 'application/json'
        
        # Format discoveryFetchStartDateTime for logging.
        $fetchStartRaw = $statusResponse.discoveryFetchStartDateTime
        if ($fetchStartRaw) {
            try {
                $fetchStartDt = [DateTime]::Parse($fetchStartRaw)
                $formattedFetchStart = $fetchStartDt.ToString("yyyy-MM-dd HH:mm:ss")
            }
            catch {
                $formattedFetchStart = $fetchStartRaw
            }
        }
        else {
            $formattedFetchStart = "N/A"
        }
        
        $isFetchRunning = $statusResponse.isDiscoveryFetchRunning
        $isComputerScanRunning = $statusResponse.isDiscoveryComputerScanRunning

        Write-Log "Discovery Fetch Start: $formattedFetchStart" -Level "INFO"
        Write-Log "Is Discovery Fetch Running: $isFetchRunning" -Level "INFO"
        Write-Log "Is Discovery Computer Scan Running: $isComputerScanRunning" -Level "INFO"

        Write-Host "Discovery Status Retrieved." -ForegroundColor Cyan
        
        return $statusResponse
    }
    catch {
        Write-Log "Failed to retrieve Discovery status: $($_.Exception.Message)" -Level "ERROR"
        Write-Error "Failed to retrieve Discovery status: $($_.Exception.Message)"
        return $null
    }
}

###############################################################################
# FUNCTION: Start-TssDiscovery
# Initiates a Discovery scan using the Secret Server API.
###############################################################################
function Start-TssDiscovery {
    [CmdletBinding()]
    param ()

    try {
        # Construct the Discovery API endpoint.
        $uri = "$Global:SecretServerURL/api/v1/discovery/run"

        # Build the JSON payload.
        $payload = @{
            data = @{
                commandType = "Discovery"
            }
        } | ConvertTo-Json

        Write-Verbose "Using Discovery URI: $uri"
        Write-Verbose "Discovery payload: $payload"

        $invokeParams = @{
            Uri         = $uri
            Method      = 'POST'
            Body        = $payload
            Headers     = @{ Authorization = "Bearer $Global:AccessToken" }
            ContentType = 'application/json'
        }

        $response = Invoke-RestMethod @invokeParams

        Write-Log "Discovery scan initiated successfully." -Level "INFO"
        Write-Host "Discovery scan initiated successfully." -ForegroundColor Green
        return $response
    }
    catch {
        Write-Log "An error occurred while running the Discovery scan: $($_.Exception.Message)" -Level "ERROR"
        Write-Error "An error occurred while running the Discovery scan: $_"
    }
}

###############################################################################
# MAIN SCRIPT EXECUTION:
###############################################################################

if (Connect-SecretServer -SecretServerUrl $Global:SecretServerURL -Token $preObtainedToken) {
    $status = Get-TssDiscoveryStatus

    if ($status -ne $null) {
        # Check if a Discovery scan is already running.
        $isFetchRunning = $status.isDiscoveryFetchRunning
        $isComputerScanRunning = $status.isDiscoveryComputerScanRunning

        # Check the fetch start time and compare with current time.
        $fetchStartRaw = $status.discoveryFetchStartDateTime
        $shouldSkipScan = $false
        
        if ($fetchStartRaw) {
            try {
                $fetchStartDt = [DateTime]::Parse($fetchStartRaw)
                $now = Get-Date
                $timeDiff = New-TimeSpan -Start $fetchStartDt -End $now
                if ($timeDiff.TotalMinutes -lt $Global:DiscoveryWaitPeriodMinutes) {
                    $shouldSkipScan = $true
                    Write-Log "Discovery scan started recently ($($fetchStartDt.ToString('yyyy-MM-dd HH:mm:ss'))). Waiting for $Global:DiscoveryWaitPeriodMinutes minutes." -Level "WARN"
                    Write-Host "Discovery scan started recently. Exiting..." -ForegroundColor Yellow
                }
            }
            catch {
                Write-Log "Error parsing fetch start time: $fetchStartRaw - $_" -Level "ERROR"
            }
        }

        if (-not $shouldSkipScan -and -not $isFetchRunning -and -not $isComputerScanRunning) {
            Write-Log "No Discovery scan in progress. Initiating new scan." -Level "INFO"
            Start-TssDiscovery
        }
    }
}

