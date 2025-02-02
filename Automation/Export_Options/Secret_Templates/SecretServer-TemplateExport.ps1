###############################################################################
# SYNOPSIS
# This script automates the process of retrieving and exporting Secret Server
# secret templates into properly formatted CSV files. It:
#   - Authenticates with Secret Server using OAuth2
#   - Retrieves all secret templates, including their field details
#   - Ensures proper field ordering (Secret Name first, Folder Path last)
#   - Handles required fields, field data types, and field names dynamically
#   - Exports each template into its own CSV file for structured import
#   - Logs all operations with real-time status updates
#
# REQUIREMENTS:
# - **PowerShell 7+ (Recommended)** (PowerShell 5.1 may work but has limitations)
# - **Internet access** (Required for API requests)
# - **Valid API credentials** (Needed to authenticate with Secret Server)
#
# USAGE EXAMPLES:
#
# 1️⃣ **Authenticate to Secret Server:**
#    Connect-SecretServer -SecretServerUrl "https://yourserver.com" -OauthUrl "https://yourserver.com/oauth2/token"
#
# 2️⃣ **Initialize required output folders:**
#    Initialize-SecretTemplateFolders -CsvDir "C:\temp\CSV_Files" -XmlDir "C:\temp\XML_Files"
#
# 3️⃣ **Retrieve all secret templates and their field data:**
#    Get-AllSecretTemplates -SecretServerUrl "https://yourserver.com" -OutputPath "C:\temp\SecretTemplates.json"
#
# 4️⃣ **Export secret templates to CSV (structured for import into Secret Server):**
#    Export-SecretTemplatesToCSV -JsonFilePath "C:\temp\SecretTemplates.json" -CsvDir "C:\temp\CSV_Files"
#
# 5️⃣ **Run all steps in a single command (Recommended for automation):**
#    Invoke-FullExport
#
# 🔹 The `Invoke-FullExport` function handles everything automatically:
#    - Checks if authentication is needed
#    - Retrieves and processes all templates
#    - Exports structured CSV files
#    - Logs success, warnings, and errors for visibility
#
# NOTE: This script is designed for environments where **regular updates** to 
# Secret Server templates are required and **manual data entry is not feasible**.
###############################################################################


###############################################################################
# VARIABLES - Configure These First
###############################################################################
$SecretServerUrl = "https://YOURURL.secretservercloud.com"
$OauthUrl        = "$SecretServerUrl/oauth2/token"
$BaseOutputDir   = "C:\temp\Secret_Templates"
$LogFilePath     = "$BaseOutputDir\SecretServer_Auth.log"
$TemplateOutput  = "$BaseOutputDir\SecretTemplates.json"
$CsvOutputDir    = "$BaseOutputDir\CSV_Files"
$XmlOutputDir    = "$BaseOutputDir\XML_Files"

###############################################################################
# FUNCTION: Write Log (Standardized Logging with Colors)
###############################################################################
Function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Timestamp = Get-Date -Format "yyyy/MM/dd HH:mm:ss"
    $LogEntry = "$Timestamp [$Level] - $Message"
    Add-Content -Path $LogFilePath -Value $LogEntry

    switch ($Level) {
        "INFO"  { Write-Host "$Timestamp [INFO] - $Message" -ForegroundColor Cyan }
        "WARN"  { Write-Host "$Timestamp [WARNING] - $Message" -ForegroundColor Yellow }
        "ERROR" { Write-Host "$Timestamp [ERROR] - $Message" -ForegroundColor Red }
        default { Write-Host "$Timestamp [LOG] - $Message" }
    }
}

###############################################################################
# FUNCTION: Initialize Required Folders
###############################################################################
Function Initialize-SecretTemplateFolders {
    param (
        [string]$CsvDir,
        [string]$XmlDir
    )

    foreach ($Dir in @($CsvDir, $XmlDir)) {
        if (-not (Test-Path $Dir)) {
            New-Item -ItemType Directory -Path $Dir | Out-Null
            Write-Log "Created Directory: $Dir" -Level "INFO"
        }
    }
}

###############################################################################
# FUNCTION: Connect to Secret Server (OAuth2 Password Grant)
###############################################################################
Function Connect-SecretServer {
    param (
        [string]$SecretServerUrl,
        [string]$OauthUrl
    )

    Write-Host "🔐 Connecting to Secret Server..." -ForegroundColor Yellow
    $creds = Get-Credential
    $Username = $creds.UserName
    $Password = $creds.GetNetworkCredential().Password

    $Body = @{
        grant_type = "password"
        username   = $Username
        password   = $Password
    }

    try {
        $AuthResponse = Invoke-RestMethod -Uri $OauthUrl -Method POST -Body $Body -ContentType "application/x-www-form-urlencoded"
        $Global:AccessToken = $AuthResponse.access_token

        if (-not $Global:AccessToken) {
            throw "No access_token returned. Check credentials."
        }

        Write-Log "Authentication Successful for user: $Username" -Level "INFO"
        Write-Host "✅ Authentication Successful" -ForegroundColor Green

    } catch {
        Write-Log "Authentication Failed for user: $Username - $($_.Exception.Message)" -Level "ERROR"
        Write-Host "❌ Authentication Failed" -ForegroundColor Red
        exit 1
    }
}

###############################################################################
# FUNCTION: Retrieve All Secret Templates & Their Fields
###############################################################################
Function Get-AllSecretTemplates {
    param (
        [string]$SecretServerUrl,
        [string]$OutputPath
    )

    if (-not $Global:AccessToken) {
        Write-Host "❌ ERROR: No valid authentication token found." -ForegroundColor Red
        exit 1
    }

    $Headers = @{
        "Authorization" = "Bearer $Global:AccessToken"
        "Content-Type"  = "application/json"
    }

    $Skip = 0
    $Take = 100  # Batch size
    $HasMore = $true
    $FinalTemplatesList = @()

    while ($HasMore) {
        # Get all templates
        $TemplatesUri = "$SecretServerUrl/api/v1/secret-templates?includeInactive=true&skip=$Skip&take=$Take"

        try {
            $TemplatesResponse = Invoke-RestMethod -Uri $TemplatesUri -Headers $Headers -Method GET
            $Templates = $TemplatesResponse.records

            if ($Templates.Count -gt 0) {
                $FinalTemplatesList += $Templates
                Write-Log "✅ Retrieved $($Templates.Count) templates (Total: $($FinalTemplatesList.Count))" -Level "INFO"
            }

            # Check if there are more pages
            $HasMore = $TemplatesResponse.hasNext
            $Skip += $Take

        } catch {
            Write-Log "❌ Failed to retrieve Secret Templates - $($_.Exception.Message)" -Level "ERROR"
            exit 1
        }
    }

    # Step 2: Retrieve Fields for Each Template
    $AllTemplatesWithFields = @()
    foreach ($Template in $FinalTemplatesList) {
        $TemplateId = $Template.id
        $TemplateName = $Template.name

        Write-Log "🔍 Fetching fields for Template: $TemplateName (ID: $TemplateId)" -Level "INFO"

        # Get fields for this template
        $FieldsUri = "$SecretServerUrl/api/v1/secret-templates/fields/search?filter.secretTemplateId=$TemplateId&take=9999999"

        try {
            $FieldsResponse = Invoke-RestMethod -Uri $FieldsUri -Headers $Headers -Method GET
            $Fields = @()

            foreach ($Field in $FieldsResponse.records) {
                $Fields += @{
                    "Name"      = $Field.name
                    "FieldId"   = $Field.id
                    "Required"  = $Field.required
                    "DataType"  = $Field.type
                }
            }

            Write-Log "✅ Retrieved $($Fields.Count) fields for template: $TemplateName" -Level "INFO"

        } catch {
            Write-Log "⚠️ Warning: Failed to retrieve fields for template: $TemplateName (ID: $TemplateId)" -Level "WARN"
            continue
        }

        # Store Template + Fields
        $AllTemplatesWithFields += @{
            "TemplateId"   = $TemplateId
            "TemplateName" = $TemplateName
            "Fields"       = $Fields
        }
    }

    # Save Final Data to JSON
    if ($AllTemplatesWithFields.Count -gt 0) {
        $AllTemplatesWithFields | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath
        Write-Log "✅ Secret Templates (With Fields) saved to $OutputPath" -Level "INFO"
    } else {
        Write-Log "❌ No Secret Templates were retrieved. Check API permissions." -Level "ERROR"
        exit 1
    }
}


###############################################################################
# FUNCTION: Export Secret Templates to CSV (Only Updates Changed Templates)
###############################################################################
Function Export-SecretTemplatesToCSV {
    param (
        [string]$JsonFilePath,
        [string]$CsvDir
    )

    if (-not (Test-Path $JsonFilePath)) {
        Write-Log "❌ ERROR: JSON file not found at $JsonFilePath" -Level "ERROR"
        exit 1
    }
    $Templates = Get-Content -Path $JsonFilePath | ConvertFrom-Json

    foreach ($Template in $Templates) {
        # Ensure Template Name is not null or empty
        $TemplateName = if ($Template.TemplateName) { 
            $Template.TemplateName -replace "[^\w\s]", "" 
        } else { 
            "UnknownTemplate"
        }

        $CsvFilePath = "$CsvDir\$TemplateName.csv"

        # Extract Field Names **with Safe DataType Handling**
        $FieldHeaders = $Template.Fields | ForEach-Object {
            $FieldName = $_.Name
            $FieldType = if ($_.DataType) { $_.DataType.ToUpper() } else { "TEXT" }  # Default to TEXT if null
            $RequiredTag = if ($_.Required) { "REQUIRED - " } else { "" }
            "$FieldName - $RequiredTag$FieldType"
        }

        # Ensure "Secret Name" is first and "Folder Path" is last
        $OrderedHeaders = @("Secret Name - REQUIRED - TEXT") + $FieldHeaders + @("Folder Path - REQUIRED - TEXT")

        # Compare with existing CSV (if it exists)
        $CsvExists = Test-Path $CsvFilePath
        $ExistingHeaders = if ($CsvExists) { Get-Content $CsvFilePath | Select-Object -First 1 } else { "" }

        if ($CsvExists -and ($ExistingHeaders -eq ($OrderedHeaders -join ","))) {
            Write-Log "✅ No changes detected for $TemplateName. Skipping CSV update." -Level "INFO"
        } else {
            # Write headers only (No empty row)
            [System.IO.File]::WriteAllLines($CsvFilePath, ($OrderedHeaders -join ","))

            Write-Log "✅ CSV Updated: $CsvFilePath" -Level "INFO"
            Write-Host "✅ CSV Updated: $CsvFilePath" -ForegroundColor Green
        }
    }
}

###############################################################################
# FUNCTION: Run All Steps
###############################################################################
Function Invoke-FullExport {
    Write-Host "🚀 Starting Full Secret Server Export Process..." -ForegroundColor Cyan

    # Connect to Secret Server only if not already authenticated
    if (-not $Global:AccessToken) {
        Write-Host "🔐 Connecting to Secret Server..." -ForegroundColor Yellow
        Connect-SecretServer -SecretServerUrl $SecretServerUrl -OauthUrl $OauthUrl
    } else {
        Write-Host "✅ Already authenticated, skipping re-authentication..." -ForegroundColor Green
    }

    # Initialize Required Folders
    Write-Host "📂 Ensuring required folders exist..." -ForegroundColor Yellow
    Initialize-SecretTemplateFolders -CsvDir $CsvOutputDir -XmlDir $XmlOutputDir

    # Retrieve All Secret Templates (USES `$TemplateOutput`)
    Write-Host "📡 Retrieving all secret templates from Secret Server..." -ForegroundColor Yellow
    Get-AllSecretTemplates -SecretServerUrl $SecretServerUrl -OutputPath $TemplateOutput

    # Export Templates to CSV (USES `$TemplateOutput`)
    Write-Host "📜 Exporting Secret Templates to CSV..." -ForegroundColor Yellow
    Export-SecretTemplatesToCSV -JsonFilePath $TemplateOutput -CsvDir $CsvOutputDir

    Write-Host "✅ Full Export Process Completed Successfully!" -ForegroundColor Green
}
