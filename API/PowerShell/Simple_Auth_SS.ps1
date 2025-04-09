# Prompt for credentials
$Username = Read-Host "Enter your Secret Server username"
$Password = Read-Host "Enter your password" -AsSecureString
$UnsecurePassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($Password)
)

# Token endpoint (no trailing slash)
$TokenUrl = "https://YOURURL.COM/oauth2/token"


# Build request body
$body = @{
    grant_type = 'password'
    username   = $Username
    password   = $UnsecurePassword
}

# Make the token request
$response = Invoke-RestMethod -Method Post -Uri $TokenUrl -Body $body -ContentType 'application/x-www-form-urlencoded'

# Output full token object
$response | Format-List
