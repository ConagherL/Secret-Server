# --- CONFIGURATION ---
$ApiUrl         = $args[0]    # Example: 'https://your-sentinelone-server.com'
$AdminUsername  = $args[1]    # Admin username with permission to change passwords
$AdminPassword  = $args[2]    # Admin password
$UserId         = $args[3]    # ID of the user whose password you want to change
$NewPassword    = $args[4]    # New password to set

# --- FUNCTIONS ---
function Get-ApiToken {
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
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body ($body | ConvertTo-Json -Depth 3) -ContentType 'application/json'
        return $response.data.token
    }
    catch {
        Write-Host "Error obtaining API token:" -ForegroundColor Red
        Write-Host $_.Exception.Message
        throw
    }
}

function Change-UserPassword {
    param(
        [string]$ApiUrl,
        [string]$ApiToken,
        [string]$UserId,
        [string]$NewPassword,
        [string]$CurrentPassword = $null
    )

    $uri = "$ApiUrl/web/api/v2.1/users/change-password"

    $body = @{ 
        data = @{
            id = $UserId
            newPassword = $NewPassword
            confirmNewPassword = $NewPassword
        }
    }

    if ($CurrentPassword) { $body.data.currentPassword = $CurrentPassword }

    $headers = @{ 
        Authorization = "ApiToken $ApiToken"
        'Content-Type' = 'application/json'
    }

    $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body ($body | ConvertTo-Json -Depth 5) -ErrorAction Stop

    return $response
}

function Validate-NewPassword {
    param(
        [string]$ApiUrl,
        [string]$Username,
        [string]$NewPassword
    )

    $uri = "$ApiUrl/web/api/v2.1/login"
    $body = @{ 
        username = $Username
        password = $NewPassword
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Body ($body | ConvertTo-Json -Depth 3) -ContentType 'application/json'
        Write-Host "Validation successful."
    }
    catch {
        Write-Host "Validation failed." -ForegroundColor Red
    }
}

# --- MAIN ---
try {
    $ApiToken = Get-ApiToken -ApiUrl $ApiUrl -Username $AdminUsername -Password $AdminPassword

    $changeResult = Change-UserPassword -ApiUrl $ApiUrl -ApiToken $ApiToken -UserId $UserId -NewPassword $NewPassword -CurrentPassword $CurrentPassword
    
    if ($changeResult.data.success -eq $true) {
        Write-Host "Password change successful. Proceeding to validate new password..."
    }
    else {
        Write-Host "Password change may have failed." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Error during password change process:" -ForegroundColor Red
    Write-Host $_.Exception.Message
}
