<#
.SYNOPSIS
Rotates password for the root SentinelOne account and returns a fresh Bearer token to Secret Server.
#>

# --- CONFIGURATION ---
$ApiUrl      = $args[0]  # https://company.sentinelone.net
$Username    = $args[1]  # Root SentinelOne account
$Password    = $args[2]  # Current password
$NewPassword = $args[3]  # New password to rotate to

$LogDir       = 'C:\Temp\Logs'
$LogFile      = Join-Path $LogDir 'SentinelOne_TokenRotation_RPC.txt'
$LoggingEnabled = $true
$DebugEnabled   = $false

# --- LOGGING SETUP ---
if ($LoggingEnabled -and !(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

function Write-Log {
    param ([string]$Message, [switch]$Force)
    if (-not $LoggingEnabled) { return }
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    if ($DebugEnabled -or $Force) {
        Add-Content -Path $LogFile -Value "$timestamp - $Message"
    }
}

# --- AUTH ---
function Get-BearerToken {
    $uri = "$ApiUrl/web/api/v2.1/users/login"
    $headers = @{ 'Content-Type' = 'application/json' }
    $body = @{ username = $Username; password = $Password } | ConvertTo-Json
    try {
        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers $headers -Body $body -ErrorAction Stop
        return $response.data.token
    } catch {
        Write-Log "Authentication failed: $($_.Exception.Message)" -Force
        throw "Login failed: $($_.Exception.Message)"
    }
}


function Get-OwnUserId {
    param ($Token)
    $uri = "$ApiUrl/web/api/v2.1/users/me"
    $headers = @{ Authorization = "Bearer $Token"; 'Content-Type' = 'application/json' }
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get -ErrorAction Stop
        return $response.data.user.id
    } catch {
        Write-Log "Failed to get current user ID: $($_.Exception.Message)" -Force
        throw "Could not retrieve own user ID"
    }
}

# --- CHANGE OWN PASSWORD ---
function Set-OwnPassword {
    param ($Token, $UserId)
    $uri = "$ApiUrl/web/api/v2.1/users/change-password"
    $headers = @{ Authorization = "Bearer $Token"; 'Content-Type' = 'application/json' }
    $body = @{
        data = @{
            id                 = $UserId
            currentPassword    = $Password
            newPassword        = $NewPassword
            confirmNewPassword = $NewPassword
        }
    } | ConvertTo-Json -Depth 5
    try {
        $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post -Body $body -ErrorAction Stop
        if ($response.data.success -ne $true) {
            throw "Password change returned success=false"
        }
        Write-Log "Password successfully changed." -Force
    } catch {
        Write-Log "Password change failed: $($_.Exception.Message)" -Force
        throw "Password update failed"
    }
}

# --- MAIN BLOCK ---
try {
    Write-Log "==== SentinelOne Token Rotation RPC Started ====" -Force

    # Auth with current password
    $initialToken = Get-BearerToken

    # Get ID
    $userId = Get-OwnUserId -Token $initialToken

    # Change password
    Set-OwnPassword -Token $initialToken -UserId $userId

    # Login with new password to get new token
    $Password = $NewPassword
    $newToken = Get-BearerToken

    if (-not $newToken) {
        Write-Log "New token is null or empty. RPC failure." -Force
        throw "RPC failure: No token received after password change."
    }

    Write-Log "New token acquired successfully." -Force

    # Return new token to Secret Server
    $dataItem = New-Object -TypeName PSObject
    $dataItem | Add-Member -MemberType NoteProperty -Name "Token" -Value $newToken
}
catch {
    Write-Log "RPC failed: $($_.Exception.Message)" -Force
    exit 1
}

# --- FINAL OUTPUT ---
return $dataItem
