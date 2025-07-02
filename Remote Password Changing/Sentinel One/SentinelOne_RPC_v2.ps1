<#
.SYNOPSIS
Changes a SentinelOne user password using the /users/change-password endpoint.
Uses an API token instead of a login token.
#>

# --- CONFIGURATION ---
$ApiUrl         = $args[0]    # Base URL of SentinelOne, e.g. https://company.sentinelone.net
$ApiToken       = $args[1]    # API token with admin privileges
$TargetUsername = $args[2]    # Username/email to search for
$NewPassword    = $args[3]    # New password to set
$LogDir         = 'C:\Temp\Logs'
$LogFile        = Join-Path $LogDir 'SentinelOne_RPC.txt'
$LoggingEnabled = $true
$DebugEnabled   = $false

# --- PREP WORK ---
if ($LoggingEnabled -and !(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# --- FUNCTIONS ---
function Write-Log {
    param (
        [string]$Message,
        [switch]$Force
    )
    if (-not $LoggingEnabled) { return }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($DebugEnabled -or $Force) {
        Add-Content -Path $LogFile -Value "$timestamp - $Message"
    }
}

function Get-UserIdByEmail {
    param (
        [string]$ApiUrl,
        [string]$ApiToken,
        [string]$Email
    )
    #$encoded = [System.Web.HttpUtility]::UrlEncode($Email)
    $uri = "$ApiUrl/web/api/v2.1/users?email__contains=$Email"
    $headers = @{ Authorization = "ApiToken $ApiToken"; 'Content-Type' = 'application/json' }

    Write-Log "Querying user by email: $Email"
    try {
        $response = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        if ($DebugEnabled) {
            Write-Log "User query response: $($response | ConvertTo-Json -Depth 3)"
        }
        return $response.data.id
    } catch {
        Write-Log "Failed to retrieve user ID: $($_.Exception.Message)" -Force
        Write-Log "==== SentinelOne RPC Password Change Finished ====" -Force
        throw "One the following error occurred: $_.Exception.Message"
        return $null
    }
}

function Set-UserPassword {
    param (
        [string]$ApiUrl,
        [string]$ApiToken,
        [string]$UserId,
        [string]$NewPassword
    )
    $uri = "$ApiUrl/web/api/v2.1/users/change-password"
    $headers = @{ Authorization = "ApiToken $ApiToken"; 'Content-Type' = 'application/json' }
    $body = @{
        data = @{
            id                 = $UserId
            newPassword        = $NewPassword
            confirmNewPassword = $NewPassword
        }
    } | ConvertTo-Json -Depth 5

    Write-Log "Sending password change request for user ID: $UserId"
    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -ErrorAction Stop
        if ($DebugEnabled) {
            Write-Log "Password change response: $($response | ConvertTo-Json -Depth 3)"
        }
        if ($response.data.success -eq $true) {
            Write-Log "Password changed successfully for user ID $UserId" -Force
        } else {
            Write-Log "Password change returned success=false." -Force
        }
    } catch {
        Write-Log "Password change failed: $($_.Exception.Message)" -Force
        if ($_.Exception.Response -and $_.Exception.Response -is [System.Net.HttpWebResponse]) {
            try {
                $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
                $responseBody = $reader.ReadToEnd()
                Write-Log "ERROR BODY: $responseBody" -Force
            } catch {
                Write-Log "Unable to read error body: $($_.Exception.Message)" -Force
            }
        }
    }
}
# --- MAIN ---
Write-Log "==== SentinelOne RPC Password Change Started ====" -Force
$userId = Get-UserIdByEmail -ApiUrl $ApiUrl -ApiToken $ApiToken -Email $TargetUsername
$success = Set-UserPassword -ApiUrl $ApiUrl -ApiToken $ApiToken -UserId $userId -NewPassword $NewPassword
Write-Log "Password change result: $success" -Force

if ($success -eq $false) {
    throw "Password change failed"
}

<#Write-Log "==== SentinelOne RPC Password Change Finished ====" -Force

# --- MAIN ---
Write-Log "==== SentinelOne RPC Password Change Started ====" -Force
$userId = Get-UserIdByEmail -ApiUrl $ApiUrl -ApiToken $ApiToken -Email $TargetUsername
if ($userId) {
    Set-UserPassword -ApiUrl $ApiUrl -ApiToken $ApiToken -UserId $userId -NewPassword $NewPassword
} else {
    Write-Log "Could not resolve user ID for $TargetUsername. Skipping password change." -Force
    Write-Log "==== SentinelOne RPC Password Change Finished ====" -Force
    throw "One of the follow errors occurred: User ID not found -- Username invalid"
}
Write-Log "==== SentinelOne RPC Password Change Finished ====" -Force
#>