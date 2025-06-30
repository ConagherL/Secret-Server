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

    $uri = "$ApiUrl/web/api/v2.1/users/login"
    $body = @{ username = $Username; password = $Password } | ConvertTo-Json -Depth 3

    Write-Log "Sending heartbeat login for $Username"
    try {
        [void](Invoke-RestMethod -Method Post -Uri $uri -Body $body -ContentType 'application/json' -ErrorAction Stop)
        Write-Log "Unexpected login success – 2FA bypassed?" -Force
        return $true
    } catch {
        Write-Log "Login attempt failed: $($_.Exception.Message)" -Force

        if ($_.Exception.Response -and $_.Exception.Response -is [System.Net.HttpWebResponse]) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Log "ERROR BODY: $responseBody" -Force

                if ($responseBody -match '"title"\s*:\s*"Required2FAConfiguration"') {
                    Write-Log "Heartbeat passed: Valid credentials confirmed via 2FA-required response." -Force
                    return $true
                } elseif ($responseBody -match '"title"\s*:\s*"Authentication Failed"') {
                    Write-Log "Heartbeat failed: Invalid username or password." -Force
                    return $false
                } else {
                    Write-Log "Heartbeat ambiguous failure." -Force
                }
            } catch {
                Write-Log "Unable to read error body: $($_.Exception.Message)" -Force
            }
        }
        return $false
    }
}

# --- MAIN ---
Write-Log "==== SentinelOne Heartbeat Started ====" -Force
$success = Test-CredentialHeartbeat -ApiUrl $ApiUrl -Username $Username -Password $Password
Write-Log "Heartbeat Result: $success" -Force
Write-Log "==== SentinelOne Heartbeat Ended ====" -Force