# Configuration Variables
$Global:YourServerURL = "https://blt.secretservercloud.com" # Replace with your actual Secret Server URL
$Global:HealthCheckEndpoint = "$Global:YourServerURL/RestApiDocs.ashx?doc=HealthCheck"
$Global:SecondaryScriptPath = "C:\Path\To\Your\SecondaryScript.ps1" # Replace with the path to your secondary script
$Global:LogFilePath = "C:\Path\To\HealthCheckLog.txt" # Replace with the path to your log file

# Function to write log messages
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "$timestamp [$Level] $Message"
    Add-Content -Path $Global:LogFilePath -Value $logMessage
}

# Function to check if the website is up
function Check-Website {
    try {
        $response = Invoke-WebRequest -Uri $Global:YourServerURL -Method Get -TimeoutSec 10 -ErrorAction Stop
        if ($response.StatusCode -eq 200) {
            Write-Log "Website is up." -Level "INFO"
            return $true
        } else {
            Write-Log "Website is not responding with status 200." -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Website is down: $_" -Level "ERROR"
        return $false
    }
}

# Function to check the health of the API endpoint
function Check-Health {
    try {
        $response = Invoke-RestMethod -Uri $Global:HealthCheckEndpoint -Method Get -ErrorAction Stop
        if ($response.status -eq "Healthy") {
            Write-Log "API is healthy." -Level "INFO"
            return $true
        } else {
            Write-Log "API is not healthy." -Level "ERROR"
            return $false
        }
    } catch {
        Write-Log "Failed to check API health: $_" -Level "ERROR"
        return $false
    }
}

# Function to execute the secondary script
function Execute-SecondaryScript {
    try {
        Write-Log "Executing secondary script..." -Level "INFO"
        & $Global:SecondaryScriptPath
        Write-Log "Secondary script executed." -Level "INFO"
    } catch {
        Write-Log "Failed to execute secondary script: $_" -Level "ERROR"
    }
}

# Main script execution
if (-not (Check-Website -and Check-Health)) {
    Execute-SecondaryScript
}
