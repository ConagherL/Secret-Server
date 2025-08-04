<#
.SYNOPSIS
    Authenticates with Secret Server REST API and returns authentication headers.
#>

# Get credentials from SS
$api_user = $args[0]
$api_password = $args[1]

# Configuration
$SecretServerUrl = 'https://YOURSSURL.com'
$TokenEndpoint = 'oauth2/token'
$LogFile = 'C:\temp\\SecretServerAuth.log'

# Uncomment to enable debug logging
# $DebugPreference = 'Continue'

#-----Logging

function Write-ToLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Exception]$Exception
    )
    
    # Always write to console
    Write-Host $Message -ForegroundColor Yellow
    
    if ($Exception) {
        Write-Host ($Exception.ToString()) -ForegroundColor Red
    }
    
    # Write to log file if debug is enabled
    if ($DebugPreference -eq 'Continue') {
        $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        try {
            Add-Content -Path $LogFile -Value "${timestamp}: $Message" -ErrorAction Stop
            
            if ($Exception) {
                Add-Content -Path $LogFile -Value "${timestamp}: $($Exception.ToString())" -ErrorAction Stop
            }
        }
        catch {
            Write-Warning "Failed to write to log file: $_"
        }
    }
}


#-----Authentication

function Get-AccessToken {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    Write-Verbose "Requesting access token from Secret Server"
    
    # OAuth2 credential
    $authBody = @{
        username   = $api_user
        password   = $api_password
        grant_type = 'password'
    }
    
    $tokenUrl = "$SecretServerUrl/$TokenEndpoint"
    
    try {
        Write-Verbose "Making token request to: $tokenUrl"
        
        $response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $authBody -ErrorAction Stop
        
        if (-not $response.access_token) {
            throw "No access token received in API response"
        }
        
        Write-Verbose "Successfully obtained access token (expires in $($response.expires_in) seconds)"
        return $response.access_token
    }
    catch {
        $errorMessage = "Failed to obtain access token: $($_.Exception.Message)"
        Write-ToLog -Message $errorMessage -Exception $_.Exception
        throw
    }
}

function Get-ApiHeaders {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    Write-Verbose "Creating API headers with Bearer token"
    
    try {
        $accessToken = Get-AccessToken
        
        $headers = @{
            'Authorization' = "Bearer $accessToken"
            'Content-Type'  = 'application/json'
        }
        
        Write-Verbose "Successfully created API headers"
        return $headers
    }
    catch {
        $errorMessage = "Failed to create API headers: $($_.Exception.Message)"
        Write-ToLog -Message $errorMessage -Exception $_.Exception
        throw
    }
}

#-----Main Execution

try {
    Write-Verbose "Starting Secret Server authentication process"
    Write-ToLog -Message "Authenticating with Secret Server at: $SecretServerUrl"
    
    $apiHeaders = Get-ApiHeaders
    
    Write-ToLog -Message "Authentication successful - headers ready for API calls"
    
    if ($DebugPreference -eq 'Continue') {
        Write-Host "Authentication completed successfully!" -ForegroundColor Green
    }
    
    return $apiHeaders
}
catch {
    Write-ToLog -Message "Authentication failed" -Exception $_.Exception
    Write-Error "Script execution failed. Check the log file for details: $LogFile"
    throw
}
