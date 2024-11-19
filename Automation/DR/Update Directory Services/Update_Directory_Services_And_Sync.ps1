<#
.SYNOPSIS
This script interacts with Delinea Secret Server to update the directory services configuration to mirror Active Directory and execute a domain synchronization.

.DESCRIPTION
The script contains functions to:
1. Establish a session with Delinea Secret Server using provided credentials.
2. Update the directory services configuration to mirror Active Directory.
3. Execute a domain synchronization.

.PARAMETER SecretServerURL
The URL of your Secret Server instance.

.EXAMPLE
# Run the script
.\Update-DirectoryServices.ps1

.NOTES
- Please make sure you have the required permissions to perform these operations. Role permissions "Administer Directory Services"
- The script uses OAuth2 for authentication.
- Success and error messages are color-coded for clarity.
#>

# Configuration Variables
$Global:YourServerURL = "https://XXXXX.secretservercloud.com" # Replace with your actual Secret Server URL

# Function to prompt for credentials and establish a new session with the Secret Server
function New-Session {
    param (
        [string]$SecretServerURL
    )

    try {
        # Prompt user for credentials
        $cred = Get-Credential
        
        # Prepare the body for the OAuth2 token request
        $body = @{
            grant_type = "password"
            username   = $cred.UserName
            password   = $cred.GetNetworkCredential().Password
        }

        # Make the OAuth2 token request
        $response = Invoke-RestMethod -Uri "$SecretServerURL/oauth2/token" -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"

        # Check if the response contains an access token
        if ($response -and $response.access_token) {
            $Global:session = $response.access_token
            Write-Host "Session established successfully." -ForegroundColor Green
            return $true
        } else {
            Write-Host "Failed to establish a session with the Secret Server." -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "An error occurred while trying to establish a session: $_" -ForegroundColor Red
        return $false
    }
}

# Function to update the directory services configuration to mirror Active Directory
function Mirror-DirectoryServices {
    param (
        [string]$SecretServerURL
    )

    try {
        # Prepare headers for the request
        $headers = @{
            "Authorization" = "Bearer $Global:session"
            "Content-Type"  = "application/json"
        }

        # Prepare the body for the PATCH request
        $body = @{
            data = @{
                userAccountOptions = @{
                    dirty = $true
                    value = "MirrorDirectory"
                }
            }
        } | ConvertTo-Json

        # Endpoint URL for updating the directory services configuration
        $url = "$SecretServerURL/api/v1/directory-services/configuration"

        # Make the PATCH request to update the configuration
        $response = Invoke-RestMethod -Uri $url -Method Patch -Headers $headers -Body $body -ErrorAction Stop

        # Output success message
        Write-Host "Directory services configuration updated successfully to mirror Active Directory." -ForegroundColor Green
    } catch {
        Write-Host "An error occurred while updating the directory services configuration: $_" -ForegroundColor Red
    }
}

# Function to execute a directory synchronization
function Sync-DirectoryServices {
    param (
        [string]$SecretServerURL
    )

    try {
        # Prepare headers for the request
        $headers = @{
            "Authorization" = "Bearer $Global:session"
            "Content-Type"  = "application/json"
        }

        # Endpoint URL for initiating the directory synchronization
        $url = "$SecretServerURL/api/v1/directory-services/synchronization-now"

        # Make the POST request to start the synchronization
        $response = Invoke-RestMethod -Uri $url -Method Post -Headers $headers -ErrorAction Stop

        # Output success message
        Write-Host "Domain Sync has been executed." -ForegroundColor Green
    } catch {
        Write-Host "An error occurred while initiating the directory services synchronization: $_" -ForegroundColor Red
    }
}

# Main script execution
if (New-Session -SecretServerURL $Global:YourServerURL) {
    Mirror-DirectoryServices -SecretServerURL $Global:YourServerURL
    Sync-DirectoryServices -SecretServerURL $Global:YourServerURL
}
