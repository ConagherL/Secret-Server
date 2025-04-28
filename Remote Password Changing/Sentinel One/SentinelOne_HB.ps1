<#
.SYNOPSIS
Validates a user's credentials against a SentinelOne instance.
Logs the authentication result to a log file.
#>

# --- CONFIGURATION ---
$ApiUrl         = $args[0]    # Example: 'https://your-sentinelone-server.com'
$Username       = $args[1]    # Username to validate
$Password       = $args[2]    # Password to validate
$LogDir         = 'C:\Temp\Logs'  # Directory where logs will be stored
$LogFile        = Join-Path $LogDir 'ValidationLog.txt'  # Full path to the log file
$DebugEnabled   = $true        # Set to $false to disable debug logging

# --- PREP WORK ---
# Ensure log directory exists
if (!(Test-Path -Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# --- FUNCTIONS ---
function Write-DebugLog {
    param(
        [string]$Message
    )
    if ($DebugEnabled) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $LogFile -Value "$timestamp - $Message"
    }
}

function Validate-UserCredentials {
    param(
        [string]$ApiUrl,
        [string]$Username,
        [string]$Password
    )

    $uri = "$ApiUrl/web/api/v2.1/login"
    $body = @{ 
        username = $Username
        password = $Password
    }

    try {
        Write-DebugLog "Attempting authentication for user: $Username"
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body ($body | ConvertTo-Json -Depth 3) -ContentType 'application/json'
        if ($response.data.token) {
            Write-Host "Validation successful." -ForegroundColor Green
            Write-DebugLog "Authentication successful for user: $Username"
            return $true
        }
        else {
            Write-Host "Validation failed." -ForegroundColor Red
            Write-DebugLog "Authentication failed for user: $Username"
            return $false
        }
    }
    catch {
        Write-Host "Validation failed with error:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        Write-DebugLog "Authentication error for user: $Username - $($_.Exception.Message)"
        return $false
    }
}

# --- MAIN ---
try {
    $validationResult = Validate-UserCredentials -ApiUrl $ApiUrl -Username $Username -Password $Password
    
    if ($validationResult) {
        Write-Host "User credentials are valid."
    }
    else {
        Write-Host "User credentials are invalid." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error during credential validation process:" -ForegroundColor Red
    Write-Host $_.Exception.Message
    Write-DebugLog "Fatal error during validation process: $($_.Exception.Message)"
}
