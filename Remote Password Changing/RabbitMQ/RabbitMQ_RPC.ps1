#### IN PROGRESS

###############################################################################
# Global Variables and Configuration
###############################################################################
# Logging Configuration
$Global:LoggingEnabled = $true
$Global:LogPath = "C:\Logs\password_rotation.log"  # Update log file path as needed

# API and User Configuration
$apiUrl          = "http://localhost:15672/api/users"
$UserName        = $args[0]
$CurrentPassword = $args[1]
$NewPassword     = $args[2]

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
# Main Script: Password Rotation
###############################################################################
Write-Log "Starting password rotation for user '$UserName'." "INFO"

# Build the full API endpoint URL for updating the user
$endpointUrl = "$apiUrl/$UserName"
Write-Log "Constructed endpoint URL: $endpointUrl." "DEBUG"

# Create the JSON payload
$body = @{
    password = $NewPassword
} | ConvertTo-Json
Write-Log "Created JSON payload for password update." "DEBUG"

# Create credentials object securely
$secureCurrentPassword = ConvertTo-SecureString $CurrentPassword -AsPlainText -Force
$userCredential = New-Object System.Management.Automation.PSCredential ($UserName, $secureCurrentPassword)
Write-Log "Created credential object for authentication." "DEBUG"

# Invoke the REST API and handle responses
try {
    Write-Log "Attempting password update via REST API..." "INFO"
    $response = Invoke-WebRequest -Uri $endpointUrl -Method Put `
        -Body $body -ContentType "application/json" `
        -Credential $userCredential -ErrorAction Stop -SkipHttpErrorCheck

    switch ($response.StatusCode) {
        204 { Write-Log "Password successfully updated for user '$UserName'. (HTTP 204 No Content)" "INFO" }
        201 { Write-Log "User '$UserName' Updated with new password. (HTTP 201 Created)" "INFO" }
        default {
            Write-Log "Unexpected HTTP status code: $($response.StatusCode). Response: $($response.Content)" "WARN"
            exit 1
        }
    }
}
catch {
    $errorDetails = $_.Exception.Message
    if ($_.Exception.Response -and $_.Exception.Response.Content) {
        $errorContent = $_.Exception.Response.Content | ConvertFrom-Json
        $errorMessage = $errorContent.error
        Write-Log "Failed to update password: $errorMessage" "ERROR"
    }
    else {
        Write-Log "Failed to update password: $_" "ERROR"
    }
    exit 1
}
