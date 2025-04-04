# Variables
$baseUrl     = "https://XXX.secretservercloud.com"      # Update with actual base URL
$usePrompt   = $true                                    # Set to $false for hardcoded credentials
$username    = "<username>"                             # Used if $usePrompt = $false
$password    = "<password>"                             # Used if $usePrompt = $false
$secretId    = 7                                        # Used if $useCSV = $false
$useCSV      = $false                                   # Set to $true to pull SecretIDs from a CSV file
$csvPath     = "C:\Path\To\SecretIDs.csv"               # CSV file with "SecretID" column
$fieldList   = "username,password,totp"                 # Comma-separated list of field slugs
$timestamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath     = "C:\temp\SecretServer_Export_$timestamp.csv"

# API endpoints
$endpoints = @{
    ApiV1      = "$baseUrl/api/v1"
    ApiV2      = "$baseUrl/api/v2"
    TokenRoute = "$baseUrl/oauth2/token"
}

# Prompt for credentials if enabled
if ($usePrompt) {
    $cred = Get-Credential
    $username = $cred.UserName
    $password = $cred.GetNetworkCredential().Password
}

# OAuth token retrieval
$creds = @{
    username   = $username
    password   = $password
    grant_type = "password"
}
$body = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
$creds.GetEnumerator() | ForEach-Object { $body.Add($_.Key, $_.Value) }
$body = $body.ToString()

try {
    $response = Invoke-RestMethod -Uri $endpoints.TokenRoute -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    $token = $response.access_token
    Write-Host "Token retrieved successfully." -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Failed to retrieve token!" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)"
    exit 1
}

# Set headers
$headers = @{ Authorization = "Bearer $token" }

# Determine SecretIDs
if ($useCSV) {
    try {
        $secretIds = Import-Csv -Path $csvPath | Select-Object -ExpandProperty SecretID
        Write-Host "`n[$($secretIds.Count)] secrets loaded from CSV." -ForegroundColor Cyan
    } catch {
        Write-Host "ERROR: Failed to load CSV!" -ForegroundColor Red
        Write-Host "Message: $($_.Exception.Message)"
        exit 1
    }
} else {
    $secretIds = @($secretId)
}

# Split fields
$fieldArray = $fieldList -split "," | ForEach-Object { $_.Trim() }

# Initialize export list
$export = @()

# Loop through each SecretID
foreach ($id in $secretIds) {
    Write-Host "`n--- Secret ID: $id ---" -ForegroundColor White
    $row = [ordered]@{ SecretID = $id }

    foreach ($field in $fieldArray) {
        if ($field -ieq "totp") {
            try {
                $totpUri = "$($endpoints.ApiV1)/one-time-password-code/$id"
                $totpResponse = Invoke-RestMethod -Method Get -Uri $totpUri -Headers $headers
                $row[$field] = ($totpResponse[0].code)
                Write-Host "TOTP: $($row[$field])" -ForegroundColor Yellow
            } catch {
                $row[$field] = ""
                Write-Host "TOTP not available or failed for SecretID $id." -ForegroundColor DarkYellow
            }
        } else {
            try {
                $fieldUri = "$($endpoints.ApiV1)/secrets/$id/fields/$field"
                $fieldResponse = Invoke-RestMethod -Method Get -Uri $fieldUri -Headers $headers
                $row[$field] = $fieldResponse
                Write-Host "Field [$field]: $fieldResponse" -ForegroundColor Green
            } catch {
                $row[$field] = ""
                Write-Host "Field '$field' failed for SecretID $id." -ForegroundColor DarkYellow
            }
        }
    }

    $export += [pscustomobject]$row
}

# Export the combined data to CSV
try {
    $export | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8
    Write-Host "`n✅ Export complete: $logPath" -ForegroundColor Cyan
} catch {
    Write-Host "ERROR: Failed to export log to CSV!" -ForegroundColor Red
    Write-Host "Message: $($_.Exception.Message)"
}
