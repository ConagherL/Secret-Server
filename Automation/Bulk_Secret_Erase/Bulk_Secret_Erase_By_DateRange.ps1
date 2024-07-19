# Variables
$apiBaseUri = "https://XXXXX.secretservercloud.com/api/v1"
$reportEndpoint = "$apiBaseUri/reports/export"
$eraseEndpoint = "$apiBaseUri/secret-erase-requests"
$authToken = "YOUR_AUTH_TOKEN"
$reportId = "YOUR_REPORT_ID"

# Function to authenticate (if needed)
function Get-AuthToken {
    # Code to obtain auth token if not provided statically
}

# Function to export report
function Export-Report {
    param (
        [string]$reportId
    )
    $headers = @{
        "Authorization" = "Bearer $authToken"
        "Content-Type" = "application/json"
    }
    $response = Invoke-RestMethod -Uri "$reportEndpoint/$reportId" -Method Get -Headers $headers
    return $response
}

# Function to send bulk Secret Erase Request
function Send-BulkSecretEraseRequest {
    param (
        [array]$secretIds
    )
    $headers = @{
        "Authorization" = "Bearer $authToken"
        "Content-Type" = "application/json"
    }
    $body = @{
        "SecretIds" = $secretIds
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri $eraseEndpoint -Method Post -Headers $headers -Body $body
    return $response
}

# Main script execution
# Step 1: Export the report
$reportData = Export-Report -reportId $reportId

# Step 2: Parse the report to extract Secret IDs (assuming CSV format for simplicity)
$csvData = ConvertFrom-Csv -InputObject $reportData

# Step 3: Filter secrets deactivated for more than 365 days
$deactivatedSecrets = $csvData | Where-Object { (Get-Date $_.DeactivatedDate) -lt (Get-Date).AddDays(-365) }

# Step 4: Collect Secret IDs
$secretIds = @()
foreach ($secret in $deactivatedSecrets) {
    $secretIds += $secret.SecretId
}

# Step 5: Send Bulk Secret Erase Request
if ($secretIds.Count -gt 0) {
    $bulkEraseResponse = Send-BulkSecretEraseRequest -secretIds $secretIds
    Write-Output "Bulk erase request sent for Secret IDs: $($secretIds -join ', ')"
} else {
    Write-Output "No secrets found for deletion."
}

Write-Output "Script execution completed."
