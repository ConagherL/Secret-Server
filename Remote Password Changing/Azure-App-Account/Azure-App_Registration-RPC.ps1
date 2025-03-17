param (
    [string]$TenantId,
    [string]$SubscriptionId,
    [string]$AppId,        # The App Registration you want to update
    [string]$AuthAppId,    # The App ID of the service principal used for authentication
    [string]$AuthSecret,   # The Client Secret of the service principal
    [string]$AuthTenant,   # The Tenant ID for authentication
    [int]$ExpirationValue = 1,  # Default: 1 Year
    [string]$ExpirationUnit = "Year",  # Options: "Day", "Month", "Year"
    [bool]$EnableLogging = $true,  # Toggle logging (Enable/Disable)
    [string]$LogFilePath = ".\AppPasswordLog.txt"  # Default log file
)

# Function to log messages
function Log-Message {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Write to console
    Write-Host $logEntry -ForegroundColor Gray

    # Write to log file if logging is enabled
    if ($EnableLogging) {
        Add-Content -Path $LogFilePath -Value $logEntry
    }
}

# Start logging
Log-Message "Script execution started."
Log-Message "Logging enabled: $EnableLogging"
Log-Message "Authenticating to Azure with Service Principal: $AuthAppId"

# Authenticate using the secondary account (Service Principal)
try {
    $securePassword = ConvertTo-SecureString $AuthSecret -AsPlainText -Force
    $credential = New-Object System.Management.Automation.PSCredential ($AuthAppId, $securePassword)

    Connect-AzAccount -ServicePrincipal -TenantId $AuthTenant -Credential $credential -SubscriptionId $SubscriptionId
    Log-Message "Successfully authenticated to Azure."
} catch {
    Log-Message "Failed to authenticate to Azure: $_" -Level "ERROR"
    exit 1
}

# Determine expiration date
$StartDate = Get-Date
switch ($ExpirationUnit.ToLower()) {
    "day"   { $EndDate = $StartDate.AddDays($ExpirationValue) }
    "month" { $EndDate = $StartDate.AddMonths($ExpirationValue) }
    "year"  { $EndDate = $StartDate.AddYears($ExpirationValue) }
    default { 
        Log-Message "Invalid expiration unit: $ExpirationUnit. Use 'Day', 'Month', or 'Year'." -Level "ERROR"
        exit 1
    }
}
Log-Message "Password expiration set to $ExpirationValue $ExpirationUnit(s) (Expires: $EndDate)"

# Generate a new password credential for the target App Registration
try {
    Log-Message "Generating a new password for App ID: $AppId"
    $PasswordCredential = New-AzADAppCredential -ObjectId $AppId -StartDate $StartDate -EndDate $EndDate
    Log-Message "Successfully generated new password."
} catch {
    Log-Message "Failed to generate password: $_" -Level "ERROR"
    exit 1
}

# Return the new password and expiration info
$result = [PSCustomObject]@{
    Password       = $PasswordCredential.SecretText
    ExpirationDate = $EndDate
    Duration       = "$ExpirationValue $ExpirationUnit(s)"
}
Log-Message "Returning password (hidden for security)."

# Disconnect from Azure
Disconnect-AzAccount
Log-Message "Disconnected from Azure."
Log-Message "Script execution completed."

return $result
