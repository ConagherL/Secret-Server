<#
.SYNOPSIS
Performs a SentinelOne "heartbeat" login using username and password.
Confirms validity of credentials based on login error response.
Logs results with configurable verbosity.
#>

# --- CONFIGURATION ---
$ApiUrl     = $args[0]    # Base URL of SentinelOne
$Username   = $args[1]    # Username/email
$Password   = $args[2]    # Password (plaintext, non-interactive)
$LogDir     = 'C:\Temp\Logs'
$LogFile    = Join-Path $LogDir 'SentinelOne_HB.txt'
$LoggingEnabled = $true
$DebugEnabled   = $false

# --- PREP WORK ---
if ($LoggingEnabled -and !(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# --- FUNCTIONS ---
function Write-Log {
    param(
        [string]$Message,
        [switch]$Force
    )
    if (-not $LoggingEnabled) { return }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($DebugEnabled -or $Force) {
        Add-Content -Path $LogFile -Value "$timestamp - $Message"
    }
}

function Test-CredentialHeartbeat {
    param(
        [string]$ApiUrl,
        [string]$Username,
        [string]$Password
    )

    # Define success codes (valid credentials that require 2FA)
    $SuccessCodes = @(4010030, 4010035)
    # Define failure codes (invalid credentials)
    $FailureCodes = @(4010001, 4010010)

    $uri = "$ApiUrl/web/api/v2.1/users/login"
    $body = @{ username = $Username; password = $Password } | ConvertTo-Json -Depth 3

    Write-Log "Sending heartbeat login for $Username"
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/json' -ErrorAction Stop
        Write-Log "Unexpected login success – 2FA bypassed?" -Force
        return $true
    } catch {
        Write-Log "Login attempt failed: $($_.Exception.Message)" -Force
        # Try to get the actual HTTP response
        $responseBody = $null
        if ($_.ErrorDetails.Message) {
            $responseBody = $_.ErrorDetails.Message
        } elseif ($_.Exception.Response) {
            try {
                $streamReader = [System.IO.StreamReader]::new($_.Exception.Response.GetResponseStream())
                $responseBody = $streamReader.ReadToEnd()
                $streamReader.Close()
            } catch {
                Write-Log "Could not read response stream: $($_.Exception.Message)" -Force
            }
        }

        if ($responseBody) {
            Write-Log "ERROR BODY: $responseBody" -Force
            try {
                $errorObj = $responseBody | ConvertFrom-Json
                # Check if errors array exists and has content
                if ($errorObj.errors -and $errorObj.errors.Count -gt 0) {
                    $errorCode = $errorObj.errors[0].code
                    $errorTitle = $errorObj.errors[0].title
                    $errorDetail = $errorObj.errors[0].detail
                    Write-Log "Error Code: $errorCode, Title: $errorTitle, Detail: $errorDetail" -Force
                    # Check for success codes (valid credentials requiring 2FA)
                    if ($SuccessCodes -contains $errorCode) {
                        Write-Log "Heartbeat passed: Valid credentials confirmed (Error Code: $errorCode)" -Force
                        return $true
                    }
                    # Check for failure codes (invalid credentials)
                    elseif ($FailureCodes -contains $errorCode) {
                        Write-Log "Heartbeat failed: Invalid username or password (Error Code: $errorCode)" -Force
                        return $false
                    }
                    else {
                        Write-Log "Unknown error code: $errorCode - Consider adding to success or failure codes list" -Force
                        return $false
                    }
                } else {
                    Write-Log "No errors array found in response" -Force
                    return $false
                }
            } catch {
                Write-Log "Could not parse JSON response: $($_.Exception.Message)" -Force
                return $false
            }
        } else {
            Write-Log "No response body available for analysis" -Force
            return $false
        }
    }
}

# --- MAIN ---
Write-Log "==== SentinelOne Heartbeat Started ====" -Force
$success = Test-CredentialHeartbeat -ApiUrl $ApiUrl -Username $Username -Password $Password
Write-Log "Heartbeat Result: $success" -Force
if ($success -eq $false) {
    Write-Log "Throwing exception for credential failure" -Force
    Write-Log "==== SentinelOne Heartbeat Ended:  Invalid credentials detected ===="
    throw "==== SentinelOne Heartbeat Ended:  Invalid credentials detected ===="
}
Write-Log "==== SentinelOne Heartbeat Ended ====" -Force