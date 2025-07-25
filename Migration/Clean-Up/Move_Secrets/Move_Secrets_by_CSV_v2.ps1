#region Configuration Variables
# =============================================================================
# CONFIGURABLE SETTINGS - Modify these values as needed for your environment
# =============================================================================

# Script Behavior
$DebugMode = $false                     # Set to $true to enable detailed debug logging
$ContinueOnError = $true                # Continue processing other records if one fails

# CSV Settings
$RequiredColumns = @('SecretID', 'FoldertoMoveSecret')
$InheritanceColumn = 'Inheritance'
$DefaultInheritanceValue = 'no'

# API Settings
$MaxRetryAttempts = 3
$RetryDelaySeconds = 2
$ApiRequestTimeoutSeconds = 30

#endregion Configuration Variables

# Fixed paths
$CsvPath = "C:\temp\Secret_Cleanup\secrets_to_move.csv"
$ServerUrl = "https://YOURSSURL"
$LogPath = "C:\temp\Secret_Cleanup\SecretMigration_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Get credentials
Write-Host "Secret Server Migration Script v2.2" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$Username = Read-Host "Enter Secret Server username"
$SecurePassword = Read-Host "Enter Secret Server password" -AsSecureString

# Convert SecureString to plain text
$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
$Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)

# Validate CSV exists
if (-not (Test-Path $CsvPath)) {
    Write-Host "Error: CSV file not found: $CsvPath" -ForegroundColor Red
    exit 1
}

# Global variables
$global:AccessToken = $null
$global:LogPath = $LogPath
$global:ErrorCount = 0
$global:SuccessCount = 0
$global:SkippedCount = 0
$global:TokenExpiryTime = $null

# Initialize logging
function Initialize-Logging {
    param([string]$LogFile)
    
    try {
        if (Test-Path $LogFile) { 
            Remove-Item $LogFile -Force 
        }
        
        $logHeader = @"
===========================================
Secret Server Migration Script v2.2 Log
Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Debug Mode: $DebugMode
===========================================

"@
        Add-Content -Path $LogFile -Value $logHeader
        Write-Host "Logging initialized: $LogFile" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to initialize logging: $($_.Exception.Message)"
        throw
    }
}

# Logging function
function Write-Log {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,
        
        [Parameter(Mandatory = $false)]
        [ValidateSet('INFO', 'WARN', 'ERROR', 'SUCCESS', 'DEBUG')]
        [string]$Level = 'INFO',
        
        [Parameter(Mandatory = $false)]
        [switch]$NoConsole
    )
    
    # Skip debug messages if debug mode is off
    if ($Level -eq 'DEBUG' -and -not $DebugMode) {
        return
    }
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    try {
        Add-Content -Path $global:LogPath -Value $logEntry -ErrorAction Stop
    }
    catch {
        Write-Warning "Failed to write to log file: $($_.Exception.Message)"
    }
    
    # Console output - only show essential messages
    if (-not $NoConsole) {
        switch ($Level) {
            'SUCCESS' { 
                # Only show key success messages
                if ($Message -like "*Authentication successful*" -or 
                    $Message -like "*CSV validation successful*" -or 
                    $Message -like "*Successfully completed migration for secret*" -or 
                    $Message -like "*Script completed successfully*") {
                    Write-Host $logEntry -ForegroundColor Green
                }
            }
            'ERROR'   { 
                Write-Host $logEntry -ForegroundColor Red 
            }
            'WARN'    { 
                # Only show important warnings
                if ($Message -like "*WARNING*" -or $Message -like "*Failed*") {
                    Write-Host $logEntry -ForegroundColor Yellow
                }
            }
            'INFO'    { 
                # Only show summary and progress messages
                if ($Message -like "*=== Processing SecretID*" -or 
                    $Message -like "*=== MIGRATION SUMMARY ===*" -or
                    $Message -like "*Total Processed*" -or
                    $Message -like "*Successful*" -or
                    $Message -like "*Failed*" -or
                    $Message -like "*Success Rate*" -or
                    $Message -like "*Starting migration*") {
                    Write-Host $logEntry -ForegroundColor White
                }
            }
            'DEBUG'   { 
                if ($DebugMode) { 
                    Write-Host $logEntry -ForegroundColor Cyan 
                }
            }
        }
    }
}

# API request function with retry logic
function Invoke-SecretServerApi {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,
        
        [Parameter(Mandatory = $true)]
        [ValidateSet('GET', 'POST', 'PATCH', 'PUT', 'DELETE')]
        [string]$Method,
        
        [Parameter(Mandatory = $false)]
        [hashtable]$Headers = @{},
        
        [Parameter(Mandatory = $false)]
        [string]$Body = $null,
        
        [Parameter(Mandatory = $false)]
        [string]$ContentType = 'application/json'
    )
    
    $attempt = 0
    $lastError = $null
    
    do {
        $attempt++
        
        try {
            Write-Log "API Request: $Method $Uri (attempt $attempt)" -Level DEBUG
            
            $requestParams = @{
                Uri = $Uri
                Method = $Method
                Headers = $Headers
                TimeoutSec = $ApiRequestTimeoutSeconds
                ErrorAction = 'Stop'
            }
            
            if ($Body) {
                $requestParams.Body = $Body
                $requestParams.ContentType = $ContentType
                Write-Log "Request body: $($Body.Substring(0, [Math]::Min(100, $Body.Length)))" -Level DEBUG
            }
            
            $response = Invoke-RestMethod @requestParams
            Write-Log "API request successful" -Level DEBUG
            return $response
        }
        catch {
            $lastError = $_
            $errorDetails = "Attempt $attempt failed: $($_.Exception.Message)"
            
            if ($_.Exception.Response) {
                try {
                    $statusCode = $_.Exception.Response.StatusCode
                    $errorDetails += " (HTTP $statusCode)"
                    
                    if ($_.ErrorDetails.Message) {
                        $errorBody = $_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue
                        if ($errorBody.message) {
                            $errorDetails += " - $($errorBody.message)"
                        }
                    }
                }
                catch { 
                    # Continue if we can't parse error response
                }
            }
            
            if ($attempt -le $MaxRetryAttempts) {
                Write-Log $errorDetails -Level WARN
                $delay = $RetryDelaySeconds * $attempt
                Write-Log "Waiting $delay seconds before retry..." -Level DEBUG
                Start-Sleep -Seconds $delay
            }
            else {
                Write-Log $errorDetails -Level ERROR
            }
        }
    } while ($attempt -le $MaxRetryAttempts)
    
    throw "API request failed after $($MaxRetryAttempts + 1) attempts. Last error: $($lastError.Exception.Message)"
}

# Token management
function Test-TokenExpiry {
    if (-not $global:TokenExpiryTime) { 
        return $false 
    }
    $timeUntilExpiry = ($global:TokenExpiryTime - (Get-Date)).TotalMinutes
    return ($timeUntilExpiry -lt 5)
}

function Get-SecretServerToken {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    param([string]$ServerUrl, [string]$Username, [string]$Password)
    
    Write-Log "Authenticating to Secret Server..." -Level INFO
    
    try {
        $authUrl = "$ServerUrl/oauth2/token"
        $body = "grant_type=password&username=$([System.Web.HttpUtility]::UrlEncode($Username))&password=$([System.Web.HttpUtility]::UrlEncode($Password))"
        $headers = @{ 'Content-Type' = 'application/x-www-form-urlencoded' }
        
        $response = Invoke-SecretServerApi -Uri $authUrl -Method Post -Headers $headers -Body $body -ContentType 'application/x-www-form-urlencoded'
        
        if ($response.access_token) {
            $global:TokenExpiryTime = (Get-Date).AddSeconds($response.expires_in - 60)
            Write-Log "Authentication successful. Token expires in $($response.expires_in) seconds." -Level SUCCESS
            return $response.access_token
        }
        else {
            throw "No access token received"
        }
    }
    catch {
        Write-Log "Authentication failed : $($_.Exception.Message)" -Level ERROR
        throw
    }
}

function Get-AuthHeader {
    if (Test-TokenExpiry) {
        Write-Log "Refreshing expired token..." -Level INFO
        $global:AccessToken = Get-SecretServerToken -ServerUrl $ServerUrl -Username $Username -Password $Password
    }
    
    if (-not $global:AccessToken) {
        throw "No access token available"
    }
    
    return @{
        'Authorization' = "Bearer $global:AccessToken"
        'Content-Type' = 'application/json'
        'Accept' = 'application/json'
    }
}

# Folder operations
function Get-FolderIdByName {
    param([string]$FolderPath, [string]$ServerUrl)
    
    Write-Log "Searching for folder : '$FolderPath'" -Level DEBUG
    
    try {
        $headers = Get-AuthHeader
        $allFolders = @()
        $skip = 0
        $take = 1000
        
        do {
            $pagedUrl = "$ServerUrl/api/v1/folders?skip=$skip&take=$take"
            $response = Invoke-SecretServerApi -Uri $pagedUrl -Method Get -Headers $headers
            
            if ($response.records) {
                $allFolders += $response.records
                Write-Log "Retrieved $($response.records.Count) folders (total : $($allFolders.Count))" -Level DEBUG
            }
            
            $skip += $take
        } while ($response.records.Count -eq $take)
        
        # Try multiple path variations
        $trimmedPath = $FolderPath.TrimStart('\')
        $pathWithBackslash = "\" + $trimmedPath
        $pathVariations = @(
            $FolderPath,
            $trimmedPath,
            $pathWithBackslash
        )
        
        foreach ($pathVariation in $pathVariations) {
            $folder = $allFolders | Where-Object { $_.folderPath -eq $pathVariation } | Select-Object -First 1
            if ($folder) {
                Write-Log "Found folder '$FolderPath' with ID : $($folder.id)" -Level DEBUG
                return $folder.id
            }
        }
        
        # Try case-insensitive
        foreach ($pathVariation in $pathVariations) {
            $folder = $allFolders | Where-Object { $_.folderPath -ieq $pathVariation } | Select-Object -First 1
            if ($folder) {
                Write-Log "Found folder '$FolderPath' with ID : $($folder.id) (case-insensitive)" -Level DEBUG
                return $folder.id
            }
        }
        
        Write-Log "Folder not found : '$FolderPath'" -Level WARN
        return $null
    }
    catch {
        Write-Log "Error searching for folder '$FolderPath' : $($_.Exception.Message)" -Level ERROR
        return $null
    }
}

# Secret operations
function Get-SecretPermissions {
    param([int]$SecretId, [string]$ServerUrl)
    
    Write-Log "Getting permissions for secret $SecretId" -Level DEBUG
    
    try {
        $headers = Get-AuthHeader
        $permissionsUrl = "$ServerUrl/api/v1/secret-permissions?filter.secretId=$SecretId&take=100"
        $response = Invoke-SecretServerApi -Uri $permissionsUrl -Method Get -Headers $headers
        
        Write-Log "Found $($response.records.Count) permission(s) for secret $SecretId" -Level INFO
        
        # Log permissions in debug mode
        foreach ($perm in $response.records) {
            $permType = if ($perm.userId) { "User : $($perm.userName)" } else { "Group : $($perm.groupName)" }
            Write-Log "  Permission : $permType - Role : $($perm.secretAccessRoleName)" -Level DEBUG
        }
        
        return $response.records
    }
    catch {
        Write-Log "Error getting permissions for secret $SecretId : $($_.Exception.Message)" -Level ERROR
        return @()
    }
}

function Move-SecretToFolder {
    param([int]$SecretId, [int]$FolderId, [string]$ServerUrl)
    
    Write-Log "Moving secret $SecretId to folder $FolderId" -Level INFO
    
    try {
        $moveUrl = "$ServerUrl/api/v1/bulk-secret-operations/move-to-folder"
        $headers = Get-AuthHeader
        
        $requestBody = @{
            data = @{
                secretIds = @($SecretId)
                folderId = $FolderId
            }
        } | ConvertTo-Json -Depth 3
        
        $response = Invoke-SecretServerApi -Uri $moveUrl -Method Post -Headers $headers -Body $requestBody
        
        if ($response.bulkOperationId) {
            Write-Log "Move operation completed. Bulk operation ID : $($response.bulkOperationId)" -Level SUCCESS
            Start-Sleep -Seconds 3  # Wait for operation to complete
            return $true
        }
        else {
            Write-Log "Move operation did not return a bulk operation ID" -Level WARN
            return $false
        }
    }
    catch {
        Write-Log "Failed to move secret $SecretId : $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Set-SecretInheritance {
    param([int]$SecretId, [bool]$EnableInheritance, [string]$ServerUrl)
    
    $action = if ($EnableInheritance) { "Enabling" } else { "Disabling" }
    Write-Log "$action inheritance for secret $SecretId" -Level INFO
    
    try {
        if ($EnableInheritance) {
            $inheritUrl = "$ServerUrl/api/v1/bulk-secret-operations/enable-inherit-permissions"
            $requestBody = @{ data = @{ secretIds = @($SecretId) } } | ConvertTo-Json -Depth 3
        }
        else {
            $inheritUrl = "$ServerUrl/api/v1/secrets/$SecretId/share"
            $requestBody = @{
                data = @{
                    inheritPermissions = @{
                        dirty = $true
                        value = $false
                    }
                }
            } | ConvertTo-Json -Depth 4
        }
        
        $headers = Get-AuthHeader
        
        $method = if ($EnableInheritance) { "Post" } else { "Patch" }
        $null = Invoke-SecretServerApi -Uri $inheritUrl -Method $method -Headers $headers -Body $requestBody
        
        Write-Log "Inheritance $($action.ToLower()) for secret $SecretId" -Level SUCCESS
        Start-Sleep -Seconds 2  # Wait for changes to take effect
        return $true
    }
    catch {
        Write-Log "Failed to set inheritance for secret $SecretId : $($_.Exception.Message)" -Level ERROR
        return $false
    }
}

function Update-SecretPermissions {
    param([int]$SecretId, [array]$OriginalPermissions, [array]$CurrentPermissions, [string]$ServerUrl)
    
    Write-Log "Replacing permissions for secret $SecretId (Current : $($CurrentPermissions.Count), Target : $($OriginalPermissions.Count))" -Level INFO
    
    $addedCount = 0
    $errorCount = 0
    
    # Create lookup for current permissions to avoid duplicates
    $currentLookup = @{}
    foreach ($perm in $CurrentPermissions) {
        $key = if ($perm.userId) { "user_$($perm.userId)_$($perm.secretAccessRoleName)" } else { "group_$($perm.groupId)_$($perm.secretAccessRoleName)" }
        $currentLookup[$key] = $true
    }
    
    # Add missing original permissions
    Write-Log "Adding missing original permissions..." -Level DEBUG
    foreach ($permission in $OriginalPermissions) {
        try {
            # Check if permission already exists
            $permKey = if ($permission.userId) { "user_$($permission.userId)_$($permission.secretAccessRoleName)" } else { "group_$($permission.groupId)_$($permission.secretAccessRoleName)" }
            
            if ($currentLookup.ContainsKey($permKey)) {
                $permType = if ($permission.userId) { "User : $($permission.userName)" } else { "Group : $($permission.groupName)" }
                Write-Log "Permission already exists : $permType - $($permission.secretAccessRoleName)" -Level DEBUG
                continue
            }
            
            # Create permission
            $createUrl = "$ServerUrl/api/v1/secret-permissions"
            $headers = Get-AuthHeader
            
            $permissionData = @{
                secretId = $SecretId
                secretAccessRoleName = $permission.secretAccessRoleName
            }
            
            if ($permission.userId -and $permission.userId -gt 0) {
                $permissionData.userId = $permission.userId
                if ($permission.userName) { $permissionData.userName = $permission.userName }
                $permType = "User : $($permission.userName)"
            }
            elseif ($permission.groupId -and $permission.groupId -gt 0) {
                $permissionData.groupId = $permission.groupId
                if ($permission.groupName) { $permissionData.groupName = $permission.groupName }
                $permType = "Group : $($permission.groupName)"
            }
            else {
                Write-Log "Skipping invalid permission for $($permission.knownAs)" -Level WARN
                continue
            }
            
            if ($permission.domainName) { $permissionData.domainName = $permission.domainName }
            
            $requestBody = $permissionData | ConvertTo-Json -Depth 3
            Write-Log "Creating permission : $permType - $($permission.secretAccessRoleName)" -Level DEBUG
            Write-Log "Permission data : $requestBody" -Level DEBUG
            
            $response = Invoke-SecretServerApi -Uri $createUrl -Method Post -Headers $headers -Body $requestBody
            
            if ($response.id) {
                Write-Log "Added permission : $permType - $($permission.secretAccessRoleName) (ID: $($response.id))" -Level SUCCESS
                $addedCount++
            }
            else {
                Write-Log "Permission creation did not return an ID for $permType" -Level ERROR
                $errorCount++
            }
        }
        catch {
            $errorMessage = $_.Exception.Message
            Write-Log "Failed to add permission for $($permission.knownAs) : $errorMessage" -Level ERROR
            
            # Try to get more specific error details
            if ($_.Exception.Response) {
                try {
                    $responseStream = $_.Exception.Response.GetResponseStream()
                    $responseStream.Position = 0
                    $reader = New-Object System.IO.StreamReader($responseStream)
                    $responseBody = $reader.ReadToEnd()
                    $reader.Close()
                    $responseStream.Close()
                    
                    if ($responseBody) {
                        Write-Log "API Error Details : $responseBody" -Level ERROR
                    }
                }
                catch {
                    Write-Log "Could not read API error details" -Level DEBUG
                }
            }
            
            if ($errorMessage -like "*already exists*" -or $errorMessage -like "*duplicate*" -or $errorMessage -like "*permission create failed*") {
                Write-Log "Permission already exists for $($permission.knownAs)" -Level DEBUG
            }
            else {
                $errorCount++
            }
        }
        
        Start-Sleep -Milliseconds 300
    }
    
    Write-Log "Permission analysis : $addedCount new, $($OriginalPermissions.Count - $addedCount) existing, $errorCount errors" -Level INFO
    Start-Sleep -Seconds 2
    
    # Get updated permissions and remove unwanted ones
    $updatedPermissions = Get-SecretPermissions -SecretId $SecretId -ServerUrl $ServerUrl
    
    # Create lookup for original permissions
    $originalLookup = @{}
    foreach ($perm in $OriginalPermissions) {
        $key = if ($perm.userId) { "user_$($perm.userId)_$($perm.secretAccessRoleName)" } else { "group_$($perm.groupId)_$($perm.secretAccessRoleName)" }
        $originalLookup[$key] = $true
    }
    
    # Remove unwanted permissions
    Write-Log "Removing unwanted permissions..." -Level DEBUG
    $removedCount = 0
    foreach ($currentPerm in $updatedPermissions) {
        $currentKey = if ($currentPerm.userId) { "user_$($currentPerm.userId)_$($currentPerm.secretAccessRoleName)" } else { "group_$($currentPerm.groupId)_$($currentPerm.secretAccessRoleName)" }
        
        if (-not $originalLookup.ContainsKey($currentKey)) {
            try {
                $deleteUrl = "$ServerUrl/api/v1/secret-permissions/$($currentPerm.id)"
                $headers = Get-AuthHeader
                $permType = if ($currentPerm.userId) { "User : $($currentPerm.userName)" } else { "Group : $($currentPerm.groupName)" }
                
                Write-Log "Removing unwanted permission : $permType - $($currentPerm.secretAccessRoleName)" -Level DEBUG
                $null = Invoke-SecretServerApi -Uri $deleteUrl -Method Delete -Headers $headers
                Write-Log "Removed unwanted permission : $permType - $($currentPerm.secretAccessRoleName)" -Level SUCCESS
                $removedCount++
            }
            catch {
                Write-Log "Failed to remove permission for $($currentPerm.knownAs) : $($_.Exception.Message)" -Level ERROR
                $errorCount++
            }
            
            Start-Sleep -Milliseconds 300
        }
        else {
            Write-Log "Keeping original permission : $($currentPerm.knownAs) - $($currentPerm.secretAccessRoleName)" -Level DEBUG
        }
    }
    
    if ($removedCount -gt 0) {
        Write-Log "Removed $removedCount unwanted permissions" -Level INFO
    }
    
    # Final verification
    Start-Sleep -Seconds 1
    $finalPermissions = Get-SecretPermissions -SecretId $SecretId -ServerUrl $ServerUrl
    $finalCount = $finalPermissions.Count
    $originalCount = $OriginalPermissions.Count
    
    if ($finalCount -eq $originalCount) {
        Write-Log "SUCCESS : Final permission count ($finalCount) matches original count ($originalCount)" -Level SUCCESS
        return $true
    }
    else {
        Write-Log "WARNING : Final permission count ($finalCount) does not match original count ($originalCount)" -Level WARN
        return $false
    }
}

# CSV validation
function Test-CsvFormat {
    param([string]$CsvPath)
    
    Write-Log "Validating CSV format..." -Level INFO
    
    try {
        $csvData = Import-Csv -Path $CsvPath -ErrorAction Stop
        
        if ($csvData.Count -eq 0) {
            throw "CSV file is empty"
        }
        
        $csvColumns = $csvData[0].PSObject.Properties.Name
        $missingColumns = $RequiredColumns | Where-Object { $_ -notin $csvColumns }
        
        if ($missingColumns) {
            throw "Missing required columns : $($missingColumns -join ', ')"
        }
        
        # Validate SecretIDs
        $invalidSecretIds = @()
        foreach ($row in $csvData) {
            try { 
                [int]$row.SecretID | Out-Null 
            }
            catch { 
                $invalidSecretIds += $row.SecretID 
            }
        }
        
        if ($invalidSecretIds.Count -gt 0) {
            throw "Invalid SecretID values : $($invalidSecretIds -join ', ')"
        }
        
        $hasInheritanceColumn = $InheritanceColumn -in $csvColumns
        
        Write-Log "CSV validation successful. Found $($csvData.Count) records." -Level SUCCESS
        Write-Log "Columns : $($csvColumns -join ', ')" -Level DEBUG
        Write-Log "Inheritance column present : $hasInheritanceColumn" -Level DEBUG
        
        return @{
            Data = $csvData
            HasInheritanceColumn = $hasInheritanceColumn
        }
    }
    catch {
        Write-Log "CSV validation failed : $($_.Exception.Message)" -Level ERROR
        throw
    }
}

# Main migration process
function Invoke-SecretMigration {
    param([array]$CsvData, [bool]$HasInheritanceColumn, [string]$ServerUrl)
    
    Write-Log "Starting migration for $($CsvData.Count) secrets..." -Level INFO
    
    # Initialize CSV audit files with headers
    $completedCsvPath = $CsvPath.Replace('.csv', '_completed.csv')
    $failedCsvPath = $CsvPath.Replace('.csv', '_failed.csv')
    
    # Remove existing files if they exist
    if (Test-Path $completedCsvPath) { Remove-Item $completedCsvPath -Force }
    if (Test-Path $failedCsvPath) { Remove-Item $failedCsvPath -Force }
    
    # Add headers
    Add-Content -Path $completedCsvPath -Value "SecretID,FolderPath,Inheritance,Status,OriginalPermissions"
    Add-Content -Path $failedCsvPath -Value "SecretID,FolderPath,Inheritance,Status,OriginalPermissions"
    
    Write-Log "Audit files initialized : $completedCsvPath and $failedCsvPath" -Level INFO
    
    $folderCache = @{}
    $processedCount = 0
    
    foreach ($record in $CsvData) {
        $secretId = [int]$record.SecretID
        $folderPath = $record.FoldertoMoveSecret.Trim()
        $inheritance = if ($HasInheritanceColumn -and $record.PSObject.Properties[$InheritanceColumn]) { 
            $record.PSObject.Properties[$InheritanceColumn].Value.ToString().ToLower().Trim()
        } else { 
            $DefaultInheritanceValue 
        }
        
        $processedCount++
        
        Write-Log " " -Level INFO
        Write-Log "=== Processing SecretID : $secretId ($processedCount of $($CsvData.Count)) ===" -Level INFO
        
        # Simple console progress indicator
        Write-Host "Processing secret $secretId ($processedCount/$($CsvData.Count))..." -ForegroundColor Cyan -NoNewline
        
        Write-Log "Target Folder : '$folderPath', Inheritance : '$inheritance'" -Level INFO
        
        if ([string]::IsNullOrWhiteSpace($folderPath)) {
            Write-Log "Empty folder path - skipping secret $secretId" -Level ERROR
            Write-Host " ✗ Empty folder path" -ForegroundColor Red
            $global:ErrorCount++
            continue
        }
        
        # Get folder ID
        $folderId = $null
        if ($folderCache.ContainsKey($folderPath)) {
            $folderId = $folderCache[$folderPath]
            Write-Log "Using cached folder ID : $folderId" -Level DEBUG
        }
        else {
            $folderId = Get-FolderIdByName -FolderPath $folderPath -ServerUrl $ServerUrl
            if ($folderId) { $folderCache[$folderPath] = $folderId }
        }
        
        if (-not $folderId) {
            Write-Log "Folder '$folderPath' not found - skipping secret $secretId" -Level ERROR
            Write-Host " ✗ Folder not found" -ForegroundColor Red
            $global:ErrorCount++
            if (-not $ContinueOnError) { throw "Failed to find folder '$folderPath'" }
            continue
        }
        
        try {
            # Step 1 & 2: Get original permissions if inheritance will be disabled
            $originalPermissions = @()
            if ($inheritance -eq "no") {
                $originalPermissions = Get-SecretPermissions -SecretId $secretId -ServerUrl $ServerUrl
                
                # CRITICAL: Don't proceed if we can't get permissions and inheritance=no
                if ($originalPermissions.Count -eq 0) {
                    Write-Log "CRITICAL : Secret $secretId has no permissions to preserve and inheritance=no. Skipping to prevent lockout." -Level ERROR
                    Write-Host " ✗ No permissions to preserve" -ForegroundColor Red
                    
                    # Log to CSV for manual review
                    $csvEntry = "$secretId,`"$folderPath`",$inheritance,FAILED - No permissions found,`"`""
                    Add-Content -Path $failedCsvPath -Value $csvEntry
                    
                    $global:ErrorCount++
                    continue
                }
                
                Write-Log "Captured $($originalPermissions.Count) permissions that will be restored after move" -Level INFO
                
                # Debug: Log each captured permission
                foreach ($perm in $originalPermissions) {
                    $permType = if ($perm.userId) { "User : $($perm.userName)" } else { "Group : $($perm.groupName)" }
                    Write-Log "  Captured permission : $permType - Role : $($perm.secretAccessRoleName)" -Level DEBUG
                }
            }
            else {
                Write-Log "Inheritance=yes : Will use folder permissions after move" -Level INFO
            }
            
            # Create permission list for CSV logging
            $permissionList = ""
            if ($originalPermissions.Count -gt 0) {
                $permissionList = ($originalPermissions | ForEach-Object { 
                    $permType = if ($_.userId) { "User:$($_.userName)" } else { "Group:$($_.groupName)" }
                    "$permType-$($_.secretAccessRoleName)"
                }) -join '; '
            }
            
            # Step 3: Move secret
            $moveSuccess = Move-SecretToFolder -SecretId $secretId -FolderId $folderId -ServerUrl $ServerUrl
            if (-not $moveSuccess) {
                Write-Log "Failed to move secret $secretId" -Level ERROR
                Write-Host " ✗ Move failed" -ForegroundColor Red
                
                $global:ErrorCount++
                continue
            }
            
            # Steps 4 & 5: Handle inheritance
            if ($inheritance -eq "yes") {
                Write-Log "Leaving inheritance enabled (secret will inherit folder permissions)" -Level INFO
                Write-Host " ✓ Success (inherited)" -ForegroundColor Green
                
                # Log successful move to CSV
                $csvEntry = "$secretId,`"$folderPath`",$inheritance,SUCCESS - Inheritance enabled,`"$permissionList`""
                Add-Content -Path $completedCsvPath -Value $csvEntry
                
                $global:SuccessCount++
            }
            elseif ($inheritance -eq "no") {
                # Step 4: Disable inheritance
                $disableSuccess = Set-SecretInheritance -SecretId $secretId -EnableInheritance $false -ServerUrl $ServerUrl
                if (-not $disableSuccess) {
                    Write-Log "Failed to disable inheritance for secret $secretId" -Level ERROR
                    Write-Host " ✗ Failed to disable inheritance" -ForegroundColor Red
                    
                    # Log to CSV for manual review with original permissions
                    $csvEntry = "$secretId,`"$folderPath`",$inheritance,FAILED - Could not disable inheritance,`"$permissionList`""
                    Add-Content -Path $failedCsvPath -Value $csvEntry
                    
                    $global:ErrorCount++
                    continue
                }
                
                # Step 5: Restore original permissions
                Write-Log "RESTORING PERMISSIONS : Applying captured permissions" -Level INFO
                Write-Log "Need to restore $($originalPermissions.Count) permission(s)" -Level DEBUG
                
                $currentPermissions = Get-SecretPermissions -SecretId $secretId -ServerUrl $ServerUrl
                Write-Log "Current permissions after disabling inheritance : $($currentPermissions.Count)" -Level DEBUG
                
                # Log current permissions for debugging
                foreach ($perm in $currentPermissions) {
                    $permType = if ($perm.userId) { "User : $($perm.userName)" } else { "Group : $($perm.groupName)" }
                    Write-Log "  Current permission : $permType - Role : $($perm.secretAccessRoleName)" -Level DEBUG
                }
                
                # Verify we can get current permissions
                if (-not $currentPermissions) {
                    Write-Log "CRITICAL : Cannot retrieve current permissions for secret $secretId after disabling inheritance" -Level ERROR
                    Write-Host " ✗ Cannot get current permissions" -ForegroundColor Red
                    
                    # Log to CSV for manual recovery with original permissions
                    $csvEntry = "$secretId,`"$folderPath`",$inheritance,FAILED - Cannot retrieve current permissions,`"$permissionList`""
                    Add-Content -Path $failedCsvPath -Value $csvEntry
                    
                    $global:ErrorCount++
                    continue
                }
                
                $replaceSuccess = Update-SecretPermissions -SecretId $secretId -OriginalPermissions $originalPermissions -CurrentPermissions $currentPermissions -ServerUrl $ServerUrl
                
                if ($replaceSuccess) {
                    # Verify final permissions
                    $finalPermissions = Get-SecretPermissions -SecretId $secretId -ServerUrl $ServerUrl
                    Write-Log "Final verification : Expected $($originalPermissions.Count), Found $($finalPermissions.Count)" -Level DEBUG
                    
                    # Log final permissions for debugging
                    foreach ($perm in $finalPermissions) {
                        $permType = if ($perm.userId) { "User : $($perm.userName)" } else { "Group : $($perm.groupName)" }
                        Write-Log "  Final permission : $permType - Role : $($perm.secretAccessRoleName)" -Level DEBUG
                    }
                    
                    if ($finalPermissions.Count -eq $originalPermissions.Count) {
                        # Double-check that the permissions actually match (not just the count)
                        $permissionsMatch = $true
                        foreach ($originalPerm in $originalPermissions) {
                            $matchFound = $false
                            foreach ($finalPerm in $finalPermissions) {
                                if (($originalPerm.userId -eq $finalPerm.userId) -and 
                                    ($originalPerm.groupId -eq $finalPerm.groupId) -and 
                                    ($originalPerm.secretAccessRoleName -eq $finalPerm.secretAccessRoleName)) {
                                    $matchFound = $true
                                    break
                                }
                            }
                            if (-not $matchFound) {
                                $permissionsMatch = $false
                                $permType = if ($originalPerm.userId) { "User : $($originalPerm.userName)" } else { "Group : $($originalPerm.groupName)" }
                                Write-Log "Missing expected permission : $permType - $($originalPerm.secretAccessRoleName)" -Level ERROR
                                break
                            }
                        }
                        
                        if ($permissionsMatch) {
                            Write-Log "Successfully completed migration for secret $secretId : $($finalPermissions.Count) permissions restored and verified" -Level SUCCESS
                            Write-Host " ✓ Success ($($finalPermissions.Count) permissions)" -ForegroundColor Green
                            
                            # Log successful move to CSV with restored permissions
                            $csvEntry = "$secretId,`"$folderPath`",$inheritance,SUCCESS - $($finalPermissions.Count) permissions restored,`"$permissionList`""
                            Add-Content -Path $completedCsvPath -Value $csvEntry
                            
                            $global:SuccessCount++
                        } else {
                            Write-Log "CRITICAL : Permission content mismatch for secret $secretId even though count matches" -Level ERROR
                            Write-Host " ✗ Permission content mismatch" -ForegroundColor Red
                            
                            # Log to CSV for manual recovery with original permissions
                            $csvEntry = "$secretId,`"$folderPath`",$inheritance,FAILED - Permission content mismatch,`"$permissionList`""
                            Add-Content -Path $failedCsvPath -Value $csvEntry
                            
                            $global:ErrorCount++
                        }
                    }
                    else {
                        Write-Log "CRITICAL : Permission count mismatch for secret $secretId. Expected $($originalPermissions.Count), got $($finalPermissions.Count)" -Level ERROR
                        Write-Host " ✗ Permission count mismatch" -ForegroundColor Red
                        
                        # Log to CSV for manual recovery with original permissions
                        $csvEntry = "$secretId,`"$folderPath`",$inheritance,FAILED - Permission count mismatch: expected $($originalPermissions.Count) got $($finalPermissions.Count),`"$permissionList`""
                        Add-Content -Path $failedCsvPath -Value $csvEntry
                        
                        $global:ErrorCount++
                    }
                }
                else {
                    Write-Log "CRITICAL : Failed to restore permissions for secret $secretId after move" -Level ERROR
                    Write-Host " ✗ Failed to restore permissions" -ForegroundColor Red
                    
                    # Log to CSV for manual recovery with original permissions
                    $csvEntry = "$secretId,`"$folderPath`",$inheritance,FAILED - Could not restore permissions,`"$permissionList`""
                    Add-Content -Path $failedCsvPath -Value $csvEntry
                    
                    $global:ErrorCount++
                }
            }
            else {
                Write-Log "Unknown inheritance value '$inheritance' - leaving inheritance enabled" -Level WARN
                Write-Host " ⚠ Unknown inheritance" -ForegroundColor Yellow
                
                # Log to CSV for manual review
                $csvEntry = "$secretId,`"$folderPath`",$inheritance,WARNING - Unknown inheritance value,`"$permissionList`""
                Add-Content -Path $failedCsvPath -Value $csvEntry
                
                $global:SuccessCount++
            }
        }
        catch {
            Write-Log "Error processing secret $secretId : $($_.Exception.Message)" -Level ERROR
            Write-Host " ✗ Error" -ForegroundColor Red
            
            # Create permission list for error case
            $permissionList = ""
            if ($originalPermissions.Count -gt 0) {
                $permissionList = ($originalPermissions | ForEach-Object { 
                    $permType = if ($_.userId) { "User:$($_.userName)" } else { "Group:$($_.groupName)" }
                    "$permType-$($_.secretAccessRoleName)"
                }) -join '; '
            }
            
            # Log to CSV for manual review with original permissions
            $csvEntry = "$secretId,`"$folderPath`",$inheritance,ERROR - $($_.Exception.Message),`"$permissionList`""
            Add-Content -Path $failedCsvPath -Value $csvEntry
            
            $global:ErrorCount++
            if (-not $ContinueOnError) { throw }
        }
    }
}

# Summary report
function Write-SummaryReport {
    Write-Log " " -Level INFO
    Write-Log "=== MIGRATION SUMMARY ===" -Level INFO
    $totalProcessed = $global:SuccessCount + $global:ErrorCount + $global:SkippedCount
    Write-Log "Total Processed : $totalProcessed" -Level INFO
    Write-Log "Successful : $global:SuccessCount" -Level SUCCESS
    Write-Log "Failed : $global:ErrorCount" -Level ERROR
    Write-Log "Skipped : $global:SkippedCount" -Level WARN
    
    if ($global:SuccessCount -gt 0) {
        $successRate = [Math]::Round(($global:SuccessCount / $totalProcessed) * 100, 1)
        Write-Log "Success Rate : $successRate%" -Level INFO
    }
    
    Write-Log "==========================" -Level INFO
}

# Cleanup
function Invoke-Cleanup {
    if ($global:AccessToken) {
        $global:AccessToken = $null
        $global:TokenExpiryTime = $null
    }
    
    if (Get-Variable -Name Password -ErrorAction SilentlyContinue) {
        Clear-Variable -Name Password -Force
    }
}

# Add required assemblies
Add-Type -AssemblyName System.Web

# Main execution
try {
    Initialize-Logging -LogFile $LogPath
    
    Write-Log "Script Configuration :" -Level INFO
    Write-Log "  CSV Path : $CsvPath" -Level INFO
    Write-Log "  Server URL : $ServerUrl" -Level INFO
    Write-Log "  Username : $Username" -Level INFO
    Write-Log "  Debug Mode : $DebugMode" -Level INFO
    Write-Log "  Continue on Error : $ContinueOnError" -Level INFO
    
    # Validate CSV
    $csvValidation = Test-CsvFormat -CsvPath $CsvPath
    
    # Authenticate
    $global:AccessToken = Get-SecretServerToken -ServerUrl $ServerUrl -Username $Username -Password $Password
    
    # Process migration
    Invoke-SecretMigration -CsvData $csvValidation.Data -HasInheritanceColumn $csvValidation.HasInheritanceColumn -ServerUrl $ServerUrl
    
    # Generate summary
    Write-SummaryReport
    
    Write-Log "Script completed successfully!" -Level SUCCESS
    
    # Determine exit code
    if ($global:ErrorCount -gt 0) {
        Write-Log "Script completed with errors. Review the log for details." -Level WARN
        $exitCode = 2
    }
    else {
        $exitCode = 0
    }
}
catch {
    Write-Log "Script failed with critical error : $($_.Exception.Message)" -Level ERROR
    Write-Log "Stack trace : $($_.ScriptStackTrace)" -Level ERROR
    
    Write-SummaryReport
    $exitCode = 1
}
finally {
    Invoke-Cleanup
    Write-Log "Log file saved to : $global:LogPath" -Level INFO
}

exit $exitCode