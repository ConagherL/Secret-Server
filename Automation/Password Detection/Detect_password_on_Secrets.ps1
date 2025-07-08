# ===================================================================
# CONFIGURATION
# ===================================================================
$SecretServerUrl = "https://yourssurl"
$OutputPath = "C:\temp\password_violations.csv"
$LogPath = "C:\temp\password_scanner.log"
$DebugMode = $false
$BatchSize = 500

# Authentication method
$Interactive    = $true  # Set to $false to use SDK authentication
$SdkProfilePath = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Config"
$SdkKeypath     = "E:\SDK\SDK_Profiles\ACCOUNTNAME\Key"

# Fields to scan
$FieldsToScan = @("secretname", "notes", "description", "comments", "url")

# Violation patterns
$ViolationPatterns = @("*password*", "*pwd*", "*pass=*", "*first 3 letters*", "*remove the*", "*login*", "*credentials*", "*temp*")

$RegexPatterns = @{
    # Pattern 1: Strong password pattern - must contain special chars, numbers, and letters
    "StrongPassword" = '(?:^|\s)([A-Za-z\d]*[!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/][A-Za-z\d!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]{7,25})(?:\s|$)'
    
    # Pattern 2: Medium complexity - at least one special char and number
    "MediumPassword" = '(?:^|\s)([A-Za-z]+[0-9]+[!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]+[A-Za-z\d!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]{5,25}|[A-Za-z]+[!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]+[0-9]+[A-Za-z\d!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]{5,25}|[0-9]+[A-Za-z]+[!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]+[A-Za-z\d!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]{5,25})(?:\s|$)'
    
    # Pattern 3: Common weak but valid passwords with special chars
    "WeakPassword" = '\b(password|Password|PASSWORD)[!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]\d+|admin[!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]\d+|user[!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]\d+|test[!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]\d+\b'
    
    # Pattern 4: Base64 encoded passwords (common in configs)
    "Base64Password" = '(?:^|\s)([A-Za-z0-9+/]{16,}={0,2})(?:\s|$)'
}


# Email settings
$EnableEmailReport = $false
$SmtpServer = "smtp.domain.com"
$From = "scanner@domain.com"
$To = "recipient@domain.com"
$EmailSubject = "Secret Server Password Violation Report"

# ===================================================================
# LOGGING FUNCTIONS
# ===================================================================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO",
        [string]$LogPath = $global:LogPath
    )
    
    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Write to console with appropriate color
    switch ($Level) {
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "WARN"  { Write-Host $logEntry -ForegroundColor Yellow }
        "INFO"  { Write-Host $logEntry -ForegroundColor White }
        "DEBUG" { if ($DebugMode) { Write-Host $logEntry -ForegroundColor Gray } }
        "SUCCESS" { Write-Host $logEntry -ForegroundColor Green }
    }
    
    # Write to log file
    try {
        $logDir = Split-Path $LogPath
        if ($logDir -and -not (Test-Path $logDir)) { 
            New-Item -Path $logDir -ItemType Directory -Force | Out-Null 
        }
        Add-Content -Path $LogPath -Value $logEntry -Encoding UTF8
    }
    catch {
        Write-Host "Failed to write to log file: $_" -ForegroundColor Red
    }
}

function Initialize-LogFile {
    param([string]$LogPath)
    
    try {
        if (Test-Path $LogPath) { Remove-Item $LogPath -Force }
        $separator = "=" * 80
        $header = @"
$separator
SECRET SERVER PASSWORD VIOLATION SCANNER LOG
Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
$separator
"@
        Set-Content -Path $LogPath -Value $header -Encoding UTF8
    }
    catch {
        Write-Host "Failed to initialize log file: $_" -ForegroundColor Red
    }
}

# ===================================================================
# CORE FUNCTIONS
# ===================================================================

function Test-RegexPatterns {
    param(
        [string]$InputText,
        [string]$FieldName
    )
    
    $regexViolations = @()
    
    # Skip if input is too short or empty
    if ([string]::IsNullOrWhiteSpace($InputText) -or $InputText.Length -lt 8) {
        return $regexViolations
    }
    
    # Skip URLs, file paths, and common non-password patterns
    if ($InputText -match '^https?://' -or 
        $InputText -match '^[A-Za-z]:\\' -or 
        $InputText -match '^/[a-zA-Z/]+' -or
        $InputText -match '^\w+\.\w+(\.\w+)*$' -or  # Domain names
        $InputText -match '^\d+\.\d+\.\d+\.\d+$' -or # IP addresses
        $InputText -match '^[A-F0-9]{8}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{4}-[A-F0-9]{12}$') { # GUIDs
        return $regexViolations
    }
    
    foreach ($patternName in $RegexPatterns.Keys) {
        $pattern = $RegexPatterns[$patternName]
        
        try {
            $matches = [regex]::Matches($InputText, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            
            foreach ($match in $matches) {
                $matchedText = if ($match.Groups.Count -gt 1) { $match.Groups[1].Value.Trim() } else { $match.Value.Trim() }
                
                # Skip if too short after trimming
                if ($matchedText.Length -lt 8) { continue }
                
                # Enhanced exclusion check
                $isExcluded = $false
                
                # Check against exclusion words
                foreach ($excludeWord in $ExcludeWords) {
                    if ($matchedText -like "*$excludeWord*") {
                        $isExcluded = $true
                        Write-Log "Excluded match '$matchedText' due to exclusion word '$excludeWord'" "DEBUG"
                        break
                    }
                }
                
                # Additional exclusion checks for edge cases
                if (-not $isExcluded) {
                    # Skip if it's all the same character repeated
                    if ($matchedText -match '^(.)\1+$') { $isExcluded = $true }
                    
                    # Skip if it looks like a version number or ID
                    if ($matchedText -match '^\d+\.\d+(\.\d+)*$') { $isExcluded = $true }
                    
                    # Skip if it's mostly whitespace or special chars only
                    if ($matchedText -match '^[\s!@#$%^&*(),.?":{}|<>~`+=_\-\[\];''\/]+$') { $isExcluded = $true }
                    
                    # For Base64 pattern, ensure it's not just random text
                    if ($patternName -eq "Base64Password" -and $matchedText.Length -lt 16) { $isExcluded = $true }
                }
                
                if (-not $isExcluded) {
                    $regexViolations += [PSCustomObject]@{
                        PatternName = $patternName
                        MatchedText = $matchedText
                        FieldName = $FieldName
                        Pattern = $pattern
                    }
                    
                    Write-Log "Regex violation found: Pattern '$patternName' matched '$matchedText' in field '$FieldName'" "DEBUG"
                }
            }
        }
        catch {
            Write-Log "Error processing regex pattern '$patternName': $($_.Exception.Message)" "ERROR"
        }
    }
    
    return $regexViolations
}

function Connect-Sdk {
    try {
        Write-Log "Attempting SDK authentication..." "INFO"
        $token = tss token -cd $SdkProfilePath -kd $SdkKeypath
        if (-not $token) { throw "No token returned from SDK command." }
        
        $global:headers = @{ 'Authorization' = "Bearer $token"; 'Content-Type' = 'application/json' }
        Write-Log "SDK Authentication Successful" "SUCCESS"
        return $global:headers
    }
    catch {
        Write-Log "SDK Authentication failed: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

function Send-EmailReport {
    param(
        [string]$CsvPath,
        [string]$LogPath,
        [int]$ViolationCount,
        [int]$SecretsScanned
    )
    
    if (-not $EnableEmailReport) {
        Write-Log "Email reporting is disabled" "INFO"
        return
    }
    
    try {
        Write-Log "Preparing email report..." "INFO"
        
        $emailBody = @"
Secret Server Password Violation Scan Report
============================================

Scan Summary:
- Secrets Scanned: $SecretsScanned
- Violations Found: $ViolationCount
- Scan Completed: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

Please review the attached CSV file for detailed violation information.
The log file contains detailed scan information and any errors encountered.

Attachments:
- password_violations.csv (Violation details)
- password_scanner.log (Scan log)

This is an automated report from the Secret Server Password Violation Scanner.
"@

        $attachments = @()
        if (Test-Path $CsvPath) { $attachments += $CsvPath }
        if (Test-Path $LogPath) { $attachments += $LogPath }
        
        if ($attachments.Count -eq 0) {
            Write-Log "No files to attach to email" "WARN"
            return
        }
        
        $mailParams = @{
            SmtpServer = $SmtpServer
            From = $From
            To = $To
            Subject = "$EmailSubject - $ViolationCount violations found"
            Body = $emailBody
            Attachments = $attachments
        }
        
        Send-MailMessage @mailParams
        Write-Log "Email report sent successfully to $To" "SUCCESS"
    }
    catch {
        Write-Log "Failed to send email report: $($_.Exception.Message)" "ERROR"
    }
}

# ===================================================================
# MAIN SCRIPT
# ===================================================================

# Initialize logging
Initialize-LogFile -LogPath $LogPath
Write-Log "Starting Secret Server Password Violation Scanner" "INFO"
Write-Log "Configuration: Server=$SecretServerUrl, Debug=$DebugMode, BatchSize=$BatchSize" "INFO"

# Authenticate
Write-Log "Starting authentication process..." "INFO"
if ($Interactive) {
    $creds = Get-Credential -Message "Enter Secret Server credentials"
    $body = @{ grant_type = "password"; username = $creds.UserName; password = $creds.GetNetworkCredential().Password }

    try {
        Write-Log "Attempting interactive authentication for user: $($creds.UserName)" "INFO"
        $token = (Invoke-RestMethod -Uri "$SecretServerUrl/oauth2/token" -Method POST -Body $body -ContentType "application/x-www-form-urlencoded").access_token
        $headers = @{ 'Authorization' = "Bearer $token"; 'Content-Type' = 'application/json' }
        Write-Log "Interactive Authentication Successful" "SUCCESS"
    }
    catch { 
        Write-Log "Authentication failed: $($_.Exception.Message)" "ERROR"
        exit 1 
    }
}
else {
    $headers = Connect-Sdk
}

# Get all secrets
Write-Log "Starting secret retrieval process..." "INFO"
$allSecrets = @()
$skip = 0
$apiBase = "$SecretServerUrl/api"
$filterParams = "filter.includeActive=true&filter.includeRestricted=true&filter.permissionRequired=1&filter.scope=All&filter.includeInactive=false"

do {
    $url = "$apiBase/v2/secrets?$filterParams&take=$BatchSize&skip=$skip"
    
    try {
        $response = Invoke-RestMethod -Uri $url -Headers $headers
        $secrets = $response.records
        
        if ($secrets) {
            $allSecrets += $secrets
            $skip += $BatchSize
            Write-Log "Retrieved $($allSecrets.Count) secrets..." "INFO"
        }
    }
    catch { 
        Write-Log "Failed to retrieve secrets: $($_.Exception.Message)" "ERROR"
        exit 1 
    }
    
} while ($secrets.Count -eq $BatchSize)

Write-Log "Retrieved $($allSecrets.Count) total secrets" "SUCCESS"

# Scan secrets for violations
Write-Log "Starting violation scanning process..." "INFO"
$violations = @()
$processedCount = 0
$errorCount = 0

foreach ($secret in $allSecrets) {
    $processedCount++
    
    if ($DebugMode -and $processedCount -gt 5) {
        Write-Log "Debug mode: Stopping after 5 secrets" "INFO"
        break
    }
    
    if ($processedCount % 50 -eq 0) {
        Write-Log "Processed $processedCount of $($allSecrets.Count) secrets..." "INFO"
    }
    
    try {
        $secretDetails = Invoke-RestMethod -Uri "$apiBase/v1/secrets/$($secret.id)" -Headers $headers
        $username = ($secretDetails.items | Where-Object { $_.fieldName -match "(username|user|login)" } | Select-Object -First 1).itemValue
        
        Write-Log "Processing secret: $($secretDetails.name) (ID: $($secret.id))" "DEBUG"
        
        foreach ($fieldName in $FieldsToScan) {
            $fieldValue = switch ($fieldName.ToLower()) {
                "secretname" { $secretDetails.name }
                "notes" { 
                    if ($secretDetails.notes) { $secretDetails.notes } 
                    else { ($secretDetails.items | Where-Object { $_.fieldName -like "*Notes*" } | Select-Object -First 1).itemValue }
                }
                "description" { 
                    if ($secretDetails.description) { $secretDetails.description }
                    else { ($secretDetails.items | Where-Object { $_.fieldName -like "*Description*" } | Select-Object -First 1).itemValue }
                }
                default { 
                    ($secretDetails.items | Where-Object { $_.fieldName -like "*$fieldName*" } | Select-Object -First 1).itemValue 
                }
            }
            
            if ([string]::IsNullOrWhiteSpace($fieldValue)) { continue }
            
            Write-Log "Checking field '$fieldName' with value: '$($fieldValue.Substring(0, [Math]::Min(50, $fieldValue.Length)))...'" "DEBUG"
            
            # Check wildcard patterns
            foreach ($pattern in $ViolationPatterns) {
                if ($fieldValue -like $pattern) {
                    Write-Log "Wildcard violation found: Pattern '$pattern' in field '$fieldName'" "DEBUG"
                    
                    $violations += [PSCustomObject]@{
                        SecretId = $secret.id
                        SecretName = $secretDetails.name
                        FolderPath = if ($secretDetails.folderPath) { $secretDetails.folderPath } else { $secret.folderPath }
                        Username = $username
                        ViolationPattern = $pattern
                        ViolationType = "Wildcard"
                        FieldName = $fieldName
                        FieldValue = $fieldValue
                        MatchedText = $fieldValue
                        ViolationCreatedBy = ""
                        ViolationCreatedDate = ""
                        GroupsWithAccess = ""
                        ScanTimestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
                    }
                }
            }
            
            # Check regex patterns
            $regexViolations = Test-RegexPatterns -InputText $fieldValue -FieldName $fieldName
            
            foreach ($regexViolation in $regexViolations) {
                Write-Log "Regex violation found: Pattern '$($regexViolation.PatternName)' matched '$($regexViolation.MatchedText)' in field '$fieldName'" "DEBUG"
                
                $violations += [PSCustomObject]@{
                    SecretId = $secret.id
                    SecretName = $secretDetails.name
                    FolderPath = if ($secretDetails.folderPath) { $secretDetails.folderPath } else { $secret.folderPath }
                    Username = $username
                    ViolationPattern = $regexViolation.PatternName
                    ViolationType = "Regex"
                    FieldName = $fieldName
                    FieldValue = $fieldValue
                    MatchedText = $regexViolation.MatchedText
                    ViolationCreatedBy = ""
                    ViolationCreatedDate = ""
                    GroupsWithAccess = ""
                    ScanTimestamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:ss'
                }
            }
        }
    }
    catch {
        $errorCount++
        Write-Log "Failed to process secret $($secret.id): $($_.Exception.Message)" "ERROR"
    }
}

Write-Log "Scanned $processedCount secrets, found $($violations.Count) violations, encountered $errorCount errors" "SUCCESS"

# Enhance violations with audit and permission data
if ($violations.Count -gt 0) {
    Write-Log "Getting audit and permission data for violations..." "INFO"
    
    $violationsBySecret = $violations | Group-Object SecretId
    $processedViolations = 0
    
    foreach ($group in $violationsBySecret) {
        $secretId = $group.Name
        $processedViolations++
        
        if ($processedViolations % 10 -eq 0) {
            Write-Log "Processing violation metadata: $processedViolations of $($violationsBySecret.Count)" "INFO"
        }
        
        # Get audit records
        $auditCreator = @{ User = "Unknown"; Date = "" }
        try {
            $auditResponse = Invoke-RestMethod -Uri "$apiBase/v1/secrets/$secretId/audits?take=20" -Headers $headers
            if ($auditResponse.records -and $auditResponse.records.Count -gt 0) {
                $recent = $auditResponse.records[0]
                $auditCreator = @{
                    User = if ($recent.displayName) { $recent.displayName } else { $recent.userName }
                    Date = $recent.dateRecorded
                }
            }
        }
        catch {
            Write-Log "Audit lookup failed for secret $secretId : $($_.Exception.Message)" "WARN"
        }
        
        # Get permissions
        $groupNames = ""
        try {
            $permissionsResponse = Invoke-RestMethod -Uri "$apiBase/v1/secret-permissions?filter.secretId=$secretId&take=50" -Headers $headers
            if ($permissionsResponse.records) {
                $groupsList = $permissionsResponse.records | ForEach-Object {
                    if ($_.groupName) {
                        $groupInfo = if ($_.knownAs) { $_.knownAs } else { $_.groupName }
                        "$groupInfo ($($_.secretAccessRoleName))"
                    }
                    if ($_.userName) {
                        $userInfo = if ($_.knownAs) { $_.knownAs } else { $_.userName }
                        "User: $userInfo ($($_.secretAccessRoleName))"
                    }
                }
                $groupNames = ($groupsList | Where-Object { $_ } | Select-Object -Unique) -join '; '
            }
            
            if ([string]::IsNullOrWhiteSpace($groupNames)) {
                $groupNames = "No_Permissions_Found"
            }
        }
        catch {
            $groupNames = "Permission_Lookup_Failed"
            Write-Log "Permission lookup failed for secret $secretId : $($_.Exception.Message)" "WARN"
        }
        
        # Update all violations for this secret
        foreach ($violation in $group.Group) {
            $violation.ViolationCreatedBy = $auditCreator.User
            $violation.ViolationCreatedDate = $auditCreator.Date
            $violation.GroupsWithAccess = $groupNames
        }
    }
}

# Export results
Write-Log "Exporting results to CSV..." "INFO"
try {
    $outputDir = Split-Path $OutputPath
    if ($outputDir -and -not (Test-Path $outputDir)) { 
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null 
        Write-Log "Created output directory: $outputDir" "INFO"
    }
    
    $violations | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    Write-Log "Results exported to: $OutputPath" "SUCCESS"
}
catch { 
    Write-Log "Export failed: $($_.Exception.Message)" "ERROR"
    exit 1 
}

# Send email report
Send-EmailReport -CsvPath $OutputPath -LogPath $LogPath -ViolationCount $violations.Count -SecretsScanned $processedCount

# Summary
Write-Log "SCAN COMPLETE" "SUCCESS"
Write-Log "Secrets scanned: $processedCount" "INFO"
Write-Log "Violations found: $($violations.Count)" "INFO"
Write-Log "Errors encountered: $errorCount" "INFO"

$wildcardCount = ($violations | Where-Object { $_.ViolationType -eq "Wildcard" }).Count
$regexCount = ($violations | Where-Object { $_.ViolationType -eq "Regex" }).Count
Write-Log "Wildcard violations: $wildcardCount" "INFO"
Write-Log "Regex violations: $regexCount" "INFO"

# Show top violation patterns
Write-Log "TOP VIOLATION PATTERNS:" "INFO"
$topPatterns = $violations | Group-Object ViolationPattern | Sort-Object Count -Descending | Select-Object -First 10
foreach ($pattern in $topPatterns) {
    Write-Log "$($pattern.Name): $($pattern.Count) violations" "INFO"
}

# Show most problematic secrets
Write-Log "SECRETS WITH MULTIPLE VIOLATIONS:" "INFO"
$multipleViolations = $violations | Group-Object SecretId | Where-Object { $_.Count -gt 3 } | Sort-Object Count -Descending | Select-Object -First 5
foreach ($group in $multipleViolations) {
    $secret = $group.Group[0]
    Write-Log "$($secret.SecretName) ($($secret.FolderPath)): $($group.Count) violations" "INFO"
}

Write-Log "Log file saved to: $LogPath" "INFO"
Write-Log "Script execution completed" "SUCCESS"