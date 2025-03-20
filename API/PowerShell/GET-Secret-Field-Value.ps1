# Variables
$baseUrl = "YOURURL"            # Update with your actual base URL
$usePrompt = $true               # Set to $false for hardcoded credentials
  $username = "<username>"        # Replace if usePrompt is $false
  $password = "<password>"        # Replace if usePrompt is $false
$secretid = 93                   # Replace with actual Secret ID
$fieldName = "password"          # Use SLUG name from API docs

# API endpoints derived from base URL
$endpoints = @{
    ApiV1      = "$baseUrl/api/v1"
    ApiV2      = "$baseUrl/api/v2"
    TokenRoute = "$baseUrl/oauth2/token"
}

# Credential Handling Based on Variable
if ($usePrompt) {
    $cred = Get-Credential
    $username = $cred.UserName
    $password = $cred.GetNetworkCredential().Password
}

# OAuth Token Retrieval
$creds = @{
    username   = $username
    password   = $password
    grant_type = "password"
}

# Convert hashtable to URL-encoded format
$body = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
$creds.GetEnumerator() | ForEach-Object { $body.Add($_.Key, $_.Value) }
$body = $body.ToString()

# Retrieve Token
try {
    $response = Invoke-RestMethod -Uri $endpoints.TokenRoute -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    $token = $response.access_token
    Write-Host "Token retrieved successfully."
} catch {
    Write-Host "ERROR: Failed to retrieve token!" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)"
    exit
}

# Set Headers
$headers = @{
    Authorization = "Bearer $token"
}

# Retrieve the Field Value
try {
    $endpoint = "$($endpoints.ApiV1)/secrets/$secretid/fields/$fieldName"
    $passwordResponse = Invoke-RestMethod -Method Get -Uri $endpoint -Headers $headers
    Write-Host "Secret Password: $($passwordResponse)" -ForegroundColor Green
} catch {
    Write-Host "ERROR: Failed to retrieve the secret password!" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)"
}
