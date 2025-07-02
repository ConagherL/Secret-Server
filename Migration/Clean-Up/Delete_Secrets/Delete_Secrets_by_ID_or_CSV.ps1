# ==============================================================================
# SECRET SERVER BULK DEACTIVATION SCRIPT
# ==============================================================================
# This script authenticates to Secret Server and deactivates secrets from a CSV file
# Based on Secret Server REST API v11.4.0

# --- CONFIGURATION ---
$ServerUrl = "https://YOURSSURL"
$CsvFilePath = "C:\temp\Secret_Cleanup\secrets_to_deactivate.csv"  # Update this path
$OutputCsvPath = "C:\temp\Secret_Cleanup\deactivation_results.csv"  # Update this path
$LogFilePath = "C:\temp\Secret_Cleanup\ss_deactivation.log"  # Update this path
$RequiredCsvColumn = "SecretID"  # Required column name in CSV file
$TimeoutMinutes = 10  # How long to wait for bulk operation completion
$DebugMode = $true  # Set to $false to disable debug logging

# --- LOGGING FUNCTIONS ---
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with color coding
    switch ($Level) {
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
        "ERROR"   { Write-Host $logEntry -ForegroundColor Red }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "DEBUG"   { if ($DebugMode) { Write-Host $logEntry -ForegroundColor Cyan } }
        default   { Write-Host $logEntry -ForegroundColor White }
    }
    
    # Write to log file
    Add-Content -Path $LogFilePath -Value $logEntry
}

function Write-Debug-Log {
    param([string]$Message)
    if ($DebugMode) {
        Write-Log $Message "DEBUG"
    }
}

# --- AUTHENTICATION ---
function Get-AuthToken {
    param([string]$Username, [SecureString]$SecurePassword)
    
    try {
        Write-Log "Attempting authentication for user: $Username"
        $TokenUrl = "$ServerUrl/oauth2/token"
        Write-Debug-Log "Token URL: $TokenUrl"
        
        $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
        )
        
        $body = @{
            username   = $Username
            password   = $passwordPlain
            grant_type = "password"
        }
        
        $response = Invoke-RestMethod -Uri $TokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
        Write-Log "Authentication successful" "SUCCESS"
        Write-Debug-Log "Token received: $($response.access_token.Substring(0,20))..."
        
        return $response.access_token
    }
    catch {
        Write-Log "Authentication failed: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# --- CSV PROCESSING ---
function Import-SecretsFromCsv {
    param([string]$FilePath)
    
    try {
        Write-Log "Reading CSV file: $FilePath"
        
        if (-not (Test-Path $FilePath)) {
            throw "CSV file not found: $FilePath"
        }
        
        $csvData = Import-Csv $FilePath
        Write-Log "Found $($csvData.Count) records in CSV file" "SUCCESS"
        Write-Debug-Log "CSV Headers: $($csvData[0].PSObject.Properties.Name -join ', ')"
        
        # Validate that SecretID column exists
        if (-not $csvData[0].PSObject.Properties.Name -contains $RequiredCsvColumn) {
            throw "CSV file must contain a '$RequiredCsvColumn' column"
        }
        
        # Extract and validate SecretIDs
        $secretIds = @()
        foreach ($row in $csvData) {
            $secretId = $null
            if ([int]::TryParse($row.$RequiredCsvColumn, [ref]$secretId) -and $secretId -gt 0) {
                $secretIds += $secretId
                Write-Debug-Log "Valid SecretID found: $secretId"
            }
            else {
                Write-Log "Invalid SecretID found in row: $($row.$RequiredCsvColumn)" "WARNING"
            }
        }
        
        Write-Log "Valid SecretIDs found: $($secretIds.Count)" "SUCCESS"
        return $secretIds
    }
    catch {
        Write-Log "Error reading CSV file: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# --- SECRET SERVER API FUNCTIONS ---
function Invoke-BulkDeactivation {
    param(
        [string]$Token,
        [int[]]$SecretIds
    )
    
    try {
        Write-Log "Starting bulk deactivation for $($SecretIds.Count) secrets"
        
        $headers = @{
            "Authorization" = "Bearer $Token"
            "Content-Type" = "application/json"
        }
        
        $requestBody = @{
            data = @{
                secretIds = $SecretIds
            }
        } | ConvertTo-Json -Depth 3
        
        Write-Debug-Log "Request Body: $requestBody"
        
        $bulkApiUrl = "$ServerUrl/api/v1/bulk-secret-operations/deactivate"
        Write-Debug-Log "Bulk API URL: $bulkApiUrl"
        
        $response = Invoke-RestMethod -Uri $bulkApiUrl -Method Post -Headers $headers -Body $requestBody
        
        Write-Log "Bulk operation initiated successfully" "SUCCESS"
        Write-Log "Bulk Operation ID: $($response.bulkOperationId)" "SUCCESS"
        
        return $response
    }
    catch {
        Write-Log "Error during bulk deactivation: $($_.Exception.Message)" "ERROR"
        if ($_.Exception.Response) {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $responseBody = $reader.ReadToEnd()
            Write-Debug-Log "Response Body: $responseBody"
        }
        throw
    }
}

function Get-BulkOperationProgress {
    param(
        [string]$Token,
        [string]$BulkOperationId
    )
    
    try {
        $headers = @{
            "Authorization" = "Bearer $Token"
        }
        
        $progressUrl = "$ServerUrl/api/v1/bulk-operations/$BulkOperationId/progress"
        $response = Invoke-RestMethod -Uri $progressUrl -Method Get -Headers $headers
        
        return $response
    }
    catch {
        Write-Log "Error getting bulk operation progress: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Wait-ForBulkOperationCompletion {
    param(
        [string]$Token,
        [string]$BulkOperationId
    )
    
    $timeout = (Get-Date).AddMinutes($TimeoutMinutes)
    $completed = $false
    
    Write-Log "Monitoring bulk operation progress (Timeout: $TimeoutMinutes minutes)"
    
    while (-not $completed -and (Get-Date) -lt $timeout) {
        try {
            $progress = Get-BulkOperationProgress -Token $Token -BulkOperationId $BulkOperationId
            
            Write-Debug-Log "Progress Response: $($progress | ConvertTo-Json -Depth 3)"
            
            $processedCount = if ($progress.processedItemCount) { $progress.processedItemCount } else { "?" }
            $totalCount = if ($progress.totalItemCount) { $progress.totalItemCount } else { "?" }
            $percentComplete = if ($progress.percentageComplete) { $progress.percentageComplete } else { 0 }
            $statusMsg = if ($progress.statusMessage) { $progress.statusMessage } else { "Processing" }
            
            # Show more meaningful progress when counts aren't available
            if ($processedCount -eq "?" -and $totalCount -eq "?") {
                Write-Host "`rProgress: $percentComplete% - Status: $statusMsg" -NoNewline -ForegroundColor Cyan
            } else {
                Write-Host "`rProgress: $processedCount/$totalCount ($percentComplete%) - Status: $statusMsg" -NoNewline -ForegroundColor Cyan
            }
            
            if ($progress.isComplete -eq $true) {
                $completed = $true
                Write-Host ""
                if ($progress.errors -and $progress.errors.Count -gt 0) {
                    Write-Log "Bulk operation completed with errors: $($progress.errors.Count) errors" "WARNING"
                    foreach ($error in $progress.errors) {
                        Write-Log "Error on $($error.itemName): $($error.errorMessage)" "ERROR"
                    }
                } else {
                    Write-Log "Bulk operation completed successfully" "SUCCESS"
                    Write-Log "Final status: $statusMsg" "SUCCESS"
                }
            }
            else {
                Start-Sleep -Seconds 5
            }
        }
        catch {
            Write-Log "Error checking progress: $($_.Exception.Message)" "WARNING"
            Start-Sleep -Seconds 10
        }
    }
    
    if (-not $completed) {
        Write-Log "Bulk operation timed out after $TimeoutMinutes minutes" "WARNING"
    }
    
    return $completed
}

# --- RESULTS PROCESSING ---
function Export-Results {
    param(
        [int[]]$SecretIds,
        [string]$BulkOperationId,
        [string]$Status,
        [string]$OutputPath
    )
    
    try {
        Write-Log "Exporting results to: $OutputPath"
        
        $results = @()
        foreach ($secretId in $SecretIds) {
            $results += [PSCustomObject]@{
                SecretID = $secretId
                BulkOperationId = $BulkOperationId
                Status = $Status
                ProcessedDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                RequestedBy = $env:USERNAME
            }
        }
        
        $results | Export-Csv -Path $OutputPath -NoTypeInformation
        Write-Log "Results exported successfully: $($results.Count) records" "SUCCESS"
    }
    catch {
        Write-Log "Error exporting results: $($_.Exception.Message)" "ERROR"
    }
}

# --- MAIN EXECUTION ---
function Main {
    try {
        Write-Host "=================================================" -ForegroundColor Magenta
        Write-Host "SECRET SERVER BULK DEACTIVATION SCRIPT" -ForegroundColor Magenta
        Write-Host "=================================================" -ForegroundColor Magenta
        
        Write-Log "Script started"
        Write-Log "Configuration: Server=$ServerUrl, CSV=$CsvFilePath, Output=$OutputCsvPath"
        
        # Get credentials
        Write-Host "Enter Secret Server credentials:" -ForegroundColor Yellow
        $username = Read-Host "Username"
        $securePassword = Read-Host "Password for $username" -AsSecureString
        
        # Authenticate
        $token = Get-AuthToken -Username $username -SecurePassword $securePassword
        
        # Import secrets from CSV
        $secretIds = Import-SecretsFromCsv -FilePath $CsvFilePath
        
        if ($secretIds.Count -eq 0) {
            Write-Log "No valid SecretIDs found in CSV file" "ERROR"
            return
        }
        
        # Confirm action
        Write-Host "About to deactivate $($secretIds.Count) secrets. Continue? (Y/N): " -ForegroundColor Yellow -NoNewline
        $confirmation = Read-Host
        
        if ($confirmation -ne "Y" -and $confirmation -ne "y") {
            Write-Log "Operation cancelled by user" "WARNING"
            return
        }
        
        # Execute bulk deactivation
        $bulkResponse = Invoke-BulkDeactivation -Token $token -SecretIds $secretIds
        
        # Monitor progress
        $completed = Wait-ForBulkOperationCompletion -Token $token -BulkOperationId $bulkResponse.bulkOperationId
        
        # Export results
        $finalStatus = if ($completed) { "Completed" } else { "Timeout" }
        Export-Results -SecretIds $secretIds -BulkOperationId $bulkResponse.bulkOperationId -Status $finalStatus -OutputPath $OutputCsvPath
        
        Write-Host "=================================================" -ForegroundColor Magenta
        Write-Log "Script completed successfully" "SUCCESS"
        Write-Log "Results saved to: $OutputCsvPath" "SUCCESS"
        Write-Host "=================================================" -ForegroundColor Magenta
    }
    catch {
        Write-Log "Script failed: $($_.Exception.Message)" "ERROR"
        Write-Host "=================================================" -ForegroundColor Red
        Write-Host "SCRIPT FAILED - Check log for details: $LogFilePath" -ForegroundColor Red
        Write-Host "=================================================" -ForegroundColor Red
    }
}

# Initialize log file
if (Test-Path $LogFilePath) {
    Remove-Item $LogFilePath -Force
}

# Execute main function
Main