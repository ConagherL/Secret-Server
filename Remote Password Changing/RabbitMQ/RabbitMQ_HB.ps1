####IN PROGRESS

###############################################################################
# Global Variables and Configuration
###############################################################################
# Logging Configuration
$Global:LoggingEnabled = $true
$Global:LogPath = "C:\Logs\heartbeat.log"  # Update log file path as needed

# API and User Configuration
$apiUrl          = "http://localhost:15672/api/whoami"
$UserName        = $args[0]
$Password        = $args[1]

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

    # Ensure the directory exists
    $logDir = Split-Path -Path $Global:LogPath -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -ItemType Directory -Path $logDir -Force | Out-Null
    }

    $logEntry | Out-File -FilePath $Global:LogPath -Append
}

###############################################################################
# Main Script: Credential Heartbeat Validation
###############################################################################
Write-Log "Starting credential heartbeat validation for user '$UserName'." "INFO"

# Create credentials object securely
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$userCredential = New-Object System.Management.Automation.PSCredential ($UserName, $securePassword)
Write-Log "Created credential object for authentication." "DEBUG"

# Invoke the REST API and handle responses
try {
    Write-Log "Performing heartbeat check..." "INFO"
    $response = Invoke-WebRequest -Uri $apiUrl -Method Get `
        -Credential $userCredential -ErrorAction Stop -SkipHttpErrorCheck

    if ($response.StatusCode -eq 200) {
        Write-Log "Credential validation successful for user '$UserName'. (HTTP 200 OK)" "INFO"
    }
    else {
        Write-Log "Credential validation failed with unexpected HTTP status code: $($response.StatusCode)." "WARN"
        exit 1
    }
}
catch {
    Write-Log "Credential validation failed: $($_.Exception.Message)" "ERROR"
    exit 1
}
