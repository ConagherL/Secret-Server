<#
.SYNOPSIS
Validates a SentinelOne login token using the /users/login/by-token endpoint.
Logs success or failure of the token authentication to a local log file.
#>

# --- CONFIGURATION ---
$ApiUrl         = $args[0]    # Base URL of SentinelOne
$LoginToken     = $args[1]    # Login token
$LogDir         = 'C:\Temp\Logs'  
$LogFile        = Join-Path $LogDir 'SentinelOne_HB.txt'
$LoggingEnabled = $true       # Set to $false to disable all logging
$DebugEnabled   = $false      # Set to $true for debug-level detail

# --- PREP WORK ---
if ($LoggingEnabled -and !(Test-Path -Path $LogDir)) {
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

function Test-TokenValidity {
    param(
        [string]$ApiUrl,
        [string]$LoginToken
    )

    $uri = "$ApiUrl/web/api/v2.1/users/login/by-token?token=$LoginToken"
    try {
        Write-Log "Attempting token validation via GET $uri"
        $response = Invoke-RestMethod -Method Get -Uri $uri -ErrorAction Stop
        Write-Log "Token is valid. User logged in successfully."
        if ($DebugEnabled) {
            Write-Log "Returned user data: $($response | ConvertTo-Json -Depth 3)"
        }
        return $true
    } catch {
        Write-Log "Token validation failed: $($_.Exception.Message)" -Force
        if ($_.Exception.Response -and $_.Exception.Response -is [System.Net.HttpWebResponse]) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Log "ERROR BODY: $responseBody" -Force
            } catch {
                Write-Log "ERROR reading error body: $($_.Exception.Message)" -Force
            }
        }
        return $false
    }
}

# --- MAIN ---
Write-Log "==== Heartbeat Token Validation Started ====" -Force
$valid = Test-TokenValidity -ApiUrl $ApiUrl -LoginToken $LoginToken
Write-Log "Validation Result: $valid" -Force
if ($valid) {
    Write-Log "==== Heartbeat validation succeeded ====" -Force
} else {
    Write-Log "==== Heartbeat validation failed ====" -Force
}