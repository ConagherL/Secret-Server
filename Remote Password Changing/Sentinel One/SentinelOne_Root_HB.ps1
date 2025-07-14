<#
.SYNOPSIS
Performs a SentinelOne "heartbeat" check using the root account's Bearer token.
Validates token with /users/login/by-token and logs error code analysis.
#>

# --- CONFIGURATION ---
$ApiUrl         = $args[0]    # Base URL of SentinelOne
$BearerToken    = $args[1]    # Bearer token to validate
$LogDir         = 'C:\Temp\Logs'
$LogFile        = Join-Path $LogDir 'SentinelOne_HB_Token.txt'
$LoggingEnabled = $true
$DebugEnabled   = $false

# --- PREP WORK ---
if ($LoggingEnabled -and !(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# --- LOGGING ---
function Write-Log {
    param([string]$Message, [switch]$Force)
    if (-not $LoggingEnabled) { return }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($DebugEnabled -or $Force) {
        Add-Content -Path $LogFile -Value "$timestamp - $Message"
    }
}

# --- HEARTBEAT FUNCTION ---
function Test-TokenHeartbeat {
    param(
        [string]$ApiUrl,
        [string]$Token
    )

    $uri = "$ApiUrl/web/api/v2.1/users/login/by-token?token=$Token"
    Write-Log "Sending token-based heartbeat request to: $uri"

    try {
        $response = Invoke-RestMethod -Uri $uri -Method Get -ErrorAction Stop
        Write-Log "Token is valid. Heartbeat passed." -Force
        if ($DebugEnabled) {
            Write-Log "Token validation response: $($response | ConvertTo-Json -Depth 3)"
        }
        return $true
    } catch {
        Write-Log "Token heartbeat failed: $($_.Exception.Message)" -Force

        $responseBody = $null
        if ($_.ErrorDetails.Message) {
            $responseBody = $_.ErrorDetails.Message
        } elseif ($_.Exception.Response) {
            try {
                $reader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                $reader.Close()
            } catch {
                Write-Log "Unable to read error stream: $($_.Exception.Message)" -Force
            }
        }

        if ($responseBody) {
            Write-Log "ERROR BODY: $responseBody" -Force
            try {
                $errorObj = $responseBody | ConvertFrom-Json
                if ($errorObj.errors -and $errorObj.errors.Count -gt 0) {
                    $errorCode  = $errorObj.errors[0].code
                    $errorTitle = $errorObj.errors[0].title
                    $errorDetail = $errorObj.errors[0].detail
                    Write-Log "Error Code: $errorCode, Title: $errorTitle, Detail: $errorDetail" -Force

                    # Optional: classify known error codes
                    switch ($errorCode) {
                        4010001 { Write-Log "Invalid token (unauthorized)" -Force }
                        4010010 { Write-Log "Expired token" -Force }
                        default { Write-Log "Unhandled error code: $errorCode" -Force }
                    }
                } else {
                    Write-Log "No error details found in JSON." -Force
                }
            } catch {
                Write-Log "Failed to parse JSON error response: $($_.Exception.Message)" -Force
            }
        } else {
            Write-Log "No error response body available." -Force
        }

        return $false
    }
}

# --- MAIN ---
Write-Log "==== SentinelOne Heartbeat (Bearer Token) Started ====" -Force
$success = Test-TokenHeartbeat -ApiUrl $ApiUrl -Token $BearerToken
Write-Log "Heartbeat Result: $success" -Force

if (-not $success) {
    Write-Log "==== SentinelOne Heartbeat FAILED ====" -Force
    throw "==== SentinelOne Heartbeat FAILED ===="
}

Write-Log "==== SentinelOne Heartbeat SUCCESS ====" -Force
