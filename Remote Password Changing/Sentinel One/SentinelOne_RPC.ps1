<#
.SYNOPSIS
Changes a SentinelOne user password using the /users/change-password endpoint.
Logs results with configurable verbosity and logging state.
#>

# --- CONFIGURATION ---
$ApiUrl         = $args[0]    # Base URL of SentinelOne (e.g., https://your-s1-server.com)
$LoginToken     = $args[1]    # Login token from /users/login
$TargetUsername = $args[2]    # The username/email to find and update
$NewPassword    = $args[3]    # New password passed in clear text
$LogDir         = 'C:\Temp\Logs'  # Log directory
$LogFile        = Join-Path $LogDir 'PasswordChangeLog.txt'
$LoggingEnabled = $true       # Toggle logging
$DebugEnabled   = $false      # Toggle verbose/debug logging

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

function Get-UserIdByUsername {
    param(
        [string]$ApiUrl,
        [string]$LoginToken,
        [string]$Username
    )
    $encodedUser = [System.Web.HttpUtility]::UrlEncode($Username)
    $uri = "$ApiUrl/web/api/v2.1/users?username=$encodedUser"
    $headers = @{ 'Authorization' = "token $LoginToken" }
    Write-Log "Querying user ID for: $Username"
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        if ($DebugEnabled) {
            Write-Log "User query response: $($response | ConvertTo-Json -Depth 3)"
        }
        return $response.data[0].id
    } catch {
        Write-Log "Failed to query user: $($_.Exception.Message)" -Force
        return $null
    }
}

function Set-UserPassword {
    param(
        [string]$ApiUrl,
        [string]$LoginToken,
        [string]$UserId,
        [string]$NewPassword
    )
    $uri = "$ApiUrl/web/api/v2.1/users/change-password"
    $headers = @{ 'Authorization' = "token $LoginToken"; 'Content-Type' = 'application/json' }
    $body = @{ data = @{ id = $UserId; newPassword = $NewPassword; confirmNewPassword = $NewPassword } } | ConvertTo-Json -Depth 3
    Write-Log "Sending password change request for user ID: $UserId"
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
        if ($DebugEnabled) {
            Write-Log "Password change response: $($response | ConvertTo-Json -Depth 3)"
        }
        if ($response.data.success -eq $true) {
            Write-Log "Password change successful for user ID: $UserId" -Force
        } else {
            Write-Log "Password change response received but success was false." -Force
        }
    } catch {
        Write-Log "Password change failed: $($_.Exception.Message)" -Force
        if ($_.Exception.Response -and $_.Exception.Response -is [System.Net.HttpWebResponse]) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Log "ERROR BODY: $responseBody" -Force
            } catch {
                Write-Log "ERROR reading error body: $($_.Exception.Message)" -Force
            }
        }
    }
}

# --- MAIN ---
Write-Log "==== Password Change Script Started ====" -Force
$userId = Get-UserIdByUsername -ApiUrl $ApiUrl -LoginToken $LoginToken -Username $TargetUsername
if ($userId) {
    Set-UserPassword -ApiUrl $ApiUrl -LoginToken $LoginToken -UserId $userId -NewPassword $NewPassword
} else {
    Write-Log "User ID not found for $TargetUsername. Aborting." -Force
}
Write-Log "==== Password Change Script Ended ====" -Force
