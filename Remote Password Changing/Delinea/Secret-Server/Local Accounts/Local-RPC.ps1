<#
.SYNOPSIS
    Resets a user's password in Secret Server using the REST API.
#>

# SS Arguments
$username = $args[0]
$newpassword = $args[1]
$api_user = $args[2]
$api_password = $args[3]

# Configuration
$SecretServerUrl = 'https://YOURSSURL.com'
$TokenEndpoint = 'oauth2/token'
$LogFile = 'C:\temp\\PasswordReset.log'

# Uncomment to enable debug logging
# $DebugPreference = 'Continue'

#-----Logging Functions

function Write-ToLog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Exception]$Exception
    )
    
    # Write to console only in debug mode
    if ($DebugPreference -eq 'Continue') {
        Write-Host $Message -ForegroundColor Yellow
        
        if ($Exception) {
            Write-Host ($Exception.ToString()) -ForegroundColor Red
        }
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

#-----Authentication Functions

function Get-AccessToken {
    [CmdletBinding()]
    [OutputType([string])]
    param()
    
    Write-Verbose "Requesting access token from Secret Server"
    
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
        
        Write-Verbose "Successfully obtained access token"
        return $response.access_token
    }
    catch {
        $errorMessage = "API Access Token could not be retrieved: $($_.Exception.Message)"
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

#-----User Management Functions

function Find-User {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,

        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    Write-Verbose "Looking up user: $UserName"
    
    $apiEndpoint = "api/v1/users/lookup?filter.searchText=$UserName"
    $requestUri = "$SecretServerUrl/$apiEndpoint"

    try {
        $response = Invoke-RestMethod -Method Get -Headers $Headers -Uri $requestUri -ErrorAction Stop
        
        Write-ToLog -Message "User lookup completed for: $UserName"
        
        if ($DebugPreference -eq 'Continue') {
            Write-ToLog -Message ($response | ConvertTo-Json -Depth 3)
        }
        
        return $response
    }
    catch {
        $errorMessage = "Failed to lookup user '$UserName': $($_.Exception.Message)"
        Write-ToLog -Message $errorMessage -Exception $_.Exception
        throw
    }
}

function Get-UserIdFromLookup {
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$LookupResponse,
        
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    Write-Verbose "Extracting user ID from lookup response"
    
    if (-not $LookupResponse.records -or $LookupResponse.records.Count -eq 0) {
        $errorMessage = "User '$UserName' not found in Secret Server"
        $exception = [System.Exception]::new($errorMessage)
        Write-ToLog -Message $errorMessage -Exception $exception
        throw $exception
    }
    
    $userId = $LookupResponse.records[0].id
    
    if (-not $userId -or $userId -le 0) {
        $errorMessage = "Invalid user ID returned for user '$UserName'"
        $exception = [System.Exception]::new($errorMessage)
        Write-ToLog -Message $errorMessage -Exception $exception
        throw $exception
    }
    
    Write-ToLog -Message "Found user ID: $userId for user: $UserName"
    return [int]$userId
}

function Reset-UserPassword {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param (
        [Parameter(Mandatory = $true)]
        [hashtable]$Headers,

        [Parameter(Mandatory = $true)]
        [int]$UserId,

        [Parameter(Mandatory = $true)]
        [SecureString]$Password,
        
        [Parameter(Mandatory = $true)]
        [string]$UserName
    )
    
    Write-Verbose "Resetting password for user ID: $UserId"
    
    $apiEndpoint = "api/v1/users/$UserId/password-reset"
    $requestUri = "$SecretServerUrl/$apiEndpoint"

    $plainTextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
    )

    $requestBody = @{
        data = @{
            password = $plainTextPassword
            userId = $UserId
        }
    } | ConvertTo-Json -Depth 3

            try {
        $response = Invoke-RestMethod `
            -Method Post `
            -Headers $Headers `
            -Uri $requestUri `
            -Body $requestBody `
            -ContentType 'application/json' `
            -ErrorAction Stop
            
        Write-ToLog -Message "Password reset successful for user: $UserName (ID: $UserId)"
        
        if ($DebugPreference -eq 'Continue') {
            Write-ToLog -Message ($response | ConvertTo-Json -Depth 3)
        }
        
        $plainTextPassword = $null
        
        return $response
    }
    catch {
        $errorMessage = "Failed to reset password for user '$UserName' (ID: $UserId): $($_.Exception.Message)"
        Write-ToLog -Message $errorMessage -Exception $_.Exception
        throw
    }
}

#-----Main Execution

try {
    Write-Verbose "Starting password reset process"
    
    if ($DebugPreference -eq 'Continue') {
        Write-ToLog -Message "Target Username: $username"
        Write-ToLog -Message "API User: $api_user"
        Write-ToLog -Message "Process started at: $(Get-Date)"
    }
    
    Write-ToLog -Message "Authenticating with Secret Server"
    $headers = Get-ApiHeaders
    
    Write-ToLog -Message "Looking up user: $username"
    $userLookup = Find-User -Headers $headers -UserName $username
    
    $userId = Get-UserIdFromLookup -LookupResponse $userLookup -UserName $username
    
    $securePassword = ConvertTo-SecureString -String $newpassword -AsPlainText -Force
    
    Write-ToLog -Message "Resetting password for user ID: $userId"
    Reset-UserPassword -Headers $headers -UserId $userId -Password $securePassword -UserName $username | Out-Null
    
    Write-ToLog -Message "Password reset completed successfully for user: $username"
    
    if ($DebugPreference -eq 'Continue') {
        Write-Host "Password reset completed successfully!" -ForegroundColor Green
        return $true
    }
}
catch {
    Write-ToLog -Message "Password reset failed for user: $username" -Exception $_.Exception
    Write-Error "Password reset failed. Check the log file for details: $LogFile"
    throw
}