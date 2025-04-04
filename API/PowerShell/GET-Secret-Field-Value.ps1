# Variables
$baseUrl     = "https://<your-instance>.secretservercloud.com" # Replace <your-instance> with your Secret Server instance name
$usePrompt   = $true                                    # Set to $false for hardcoded credentials
$username    = "<username>"                             # Used if $usePrompt = $false
$password    = "<password>"                             # Used if $usePrompt = $false
$secretId    = 7                                        # Used if $useCSV = $false
$useCSV      = $false                                   # Set to $true to pull SecretIDs from a CSV file
$csvPath     = "C:\temp\SecretIDs.csv"               # CSV file must include a header row with a "SecretID" column
$fieldList   = "domain,username,password,totp"                 # Comma-separated list of field slugs
$timeStamp   = Get-Date -Format "yyyyMMdd_HHmmss"
$logPath     = "C:\temp\SecretServer_Export_$timeStamp.csv"

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
    if ($_.Exception.Response) {
        $responseStream = $_.Exception.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseStream)
        $responseBody = $reader.ReadToEnd()
        Write-Host "HTTP Status Code: $($_.Exception.Response.StatusCode)" -ForegroundColor Yellow
        Write-Host "Response Body: $responseBody" -ForegroundColor Yellow
    }
    exit 1
}

# Determine SecretIDs
if ($useCSV) {
    try {
        $csvData = Import-Csv -Path $csvPath
        if (-not $csvData[0].PSObject.Properties.Name -contains "SecretID") {
            Write-Host "ERROR: The CSV file does not contain a 'SecretID' column!" -ForegroundColor Red
            exit 1
        }
        $secretIds = $csvData | Select-Object -ExpandProperty SecretID
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
$fieldList = $fieldList.Trim() -replace "\s*,\s*", ","
$fieldArray = $fieldList -split "," | ForEach-Object { $_.Trim() }

# Initialize export list
$export = @()

# Loop through each SecretID
foreach ($id in $secretIds) {
    Write-Host "`n--- Secret ID: $id ---" -ForegroundColor White
    $row = [ordered]@{ SecretID = $id }

    foreach ($field in $fieldArray) {
        try {
            if ($field -ieq "totp") {
                $totpUri = "$($endpoints.ApiV1)/one-time-password-code/$id"
                $totpResponse = Invoke-RestMethod -Method Get -Uri $totpUri -Headers $headers
                if ($totpResponse -and $totpResponse[0] -and $totpResponse[0].code) {
                    $row[$field] = $totpResponse[0].code
                    Write-Host "TOTP: $($row[$field])" -ForegroundColor Yellow
                } else {
                    $row[$field] = ""
                    Write-Host "TOTP not available or invalid response for SecretID $id." -ForegroundColor DarkYellow
                }
            } else {
                $fieldUri = "$($endpoints.ApiV1)/secrets/$id/fields/$field"
                $fieldResponse = Invoke-RestMethod -Method Get -Uri $fieldUri -Headers $headers
                if ($fieldResponse -and $fieldResponse -is [string]) {
                    $row[$field] = $fieldResponse
                    Write-Host "Field [$field]: $fieldResponse" -ForegroundColor Green
                } else {
                    $row[$field] = ""
                    Write-Host "Field '$field' response structure is invalid or empty for SecretID $id." -ForegroundColor DarkYellow
                }
            }
        } catch {
            $row[$field] = ""
            Write-Host "Field '$field' failed for SecretID $id." -ForegroundColor DarkYellow
        }
    }

    $export += $row
}

# Export the combined data to CSV
if ($export.Count -gt 0) {
    try {
        $export | Export-Csv -Path $logPath -NoTypeInformation -Encoding UTF8
        Write-Host "`n✅ Export complete: $logPath" -ForegroundColor Cyan
    } catch {
        Write-Host "ERROR: Failed to export log to CSV!" -ForegroundColor Red
        Write-Host "Message: $($_.Exception.Message)"
    }
} else {
    Write-Host "No data to export. The $export array is empty." -ForegroundColor Yellow
}
