<#
.SYNOPSIS
    This script automates the process of exporting Secret Server secret templates 
    into properly formatted CSV and XML files.

.DESCRIPTION
    The script:
    - Authenticates with Secret Server
    - Retrieves all secret templates and their field details
    - Ensures proper field ordering (Secret Name first, Folder Path last)
    - Exports each template into its own CSV file
    - Converts CSVs into properly structured XML files for import into Secret Server
    - Extracts folder paths from CSVs and generates an XML file for folder creation

.REQUIREMENTS
    - PowerShell 7+ (Recommended) (PowerShell 5.1 may work but has limitations)
    - Internet access (Required for API requests)
    - Valid API credentials (Needed to query Secret Server)

.FUNCTIONS INCLUDED
    - Connect-SecretServer       : Authenticate to Secret Server using OAuth2
    - Initialize-SecretTemplateFolders : Ensure all necessary output folders exist
    - Get-AllSecretTemplates     : Retrieve all secret templates and field details
    - Export-SecretTemplatesToCSV: Convert template data to CSV format
    - Convert-CSVToXML           : Convert CSV secret data into an XML file for import
    - Convert-FoldersToXML       : Extract folder structure from CSVs and generate folder XML
    - Invoke-FullExport          : Runs all steps automatically in the correct order

.EXAMPLES
    # Authenticate to Secret Server
    Connect-SecretServer -SecretServerUrl "https://yourserver.com" -OauthUrl "https://yourserver.com/oauth2/token"

    # Initialize required output folders
    Initialize-SecretTemplateFolders -CsvDir "C:\temp\CSV_Files" -XmlDir "C:\temp\XML_Files"

    # Retrieve all secret templates and fields
    Get-AllSecretTemplates -SecretServerUrl "https://yourserver.com" -OutputPath "C:\temp\SecretTemplates.json"

    # Export Secret Templates to CSV
    Export-SecretTemplatesToCSV -JsonFilePath "C:\temp\SecretTemplates.json" -CsvDir "C:\temp\CSV_Files"

    # Convert Secret CSVs to XML
    Convert-CSVToXML

    # Convert Folder Structure to XML
    Convert-FoldersToXML

    # Run all steps automatically (Recommended)
    Invoke-FullExport

.NOTES
    - Running Invoke-FullExport will execute all steps in sequence.
    - Convert-FoldersToXML ensures parent folders are created before subfolders.
    - CSVs should not contain modified headers (e.g., Required, Data Type) when converting to XML.

#>



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
# FUNCTION: Convert All CSVs to a Single XML File for Secret Import
###############################################################################
Function Convert-CSVToXML {
    Write-Host "📂 Converting all CSVs to XML..." -ForegroundColor Yellow

    # Use predefined paths
    $CsvDir = $CsvOutputDir
    $JsonFilePath = $TemplateOutput
    $XmlOutputFile = "$XmlOutputDir\Secrets.xml"

    # Validate Paths Before Execution
    if (-not (Test-Path $CsvDir)) {
        Write-Log "❌ ERROR: CSV Directory not found: $CsvDir" -Level "ERROR"
        exit 1
    }

    if (-not (Test-Path $JsonFilePath)) {
        Write-Log "❌ ERROR: SecretTemplates.json not found: $JsonFilePath" -Level "ERROR"
        exit 1
    }
    $Templates = Get-Content -Path $JsonFilePath | ConvertFrom-Json

    # Initialize XML Document
    $XmlDocument = New-Object System.Xml.XmlDocument
    $XmlDeclaration = $XmlDocument.CreateXmlDeclaration("1.0", "utf-16", $null)
    $XmlDocument.AppendChild($XmlDeclaration) | Out-Null

    # Root XML Node: <ImportFile>
    $ImportFileNode = $XmlDocument.CreateElement("ImportFile")
    $XmlDocument.AppendChild($ImportFileNode) | Out-Null

    # Create <Secrets> Node
    $SecretsNode = $XmlDocument.CreateElement("Secrets")
    $ImportFileNode.AppendChild($SecretsNode) | Out-Null

    # Process each CSV file in the directory
    $CsvFiles = Get-ChildItem -Path $CsvDir -Filter "*.csv"
    
    if ($CsvFiles.Count -eq 0) {
        Write-Log "⚠️ WARNING: No CSV files found in $CsvDir. XML will not be created." -Level "WARN"
        exit 0
    }

    $SecretCount = 0  # Track number of secrets added

    foreach ($CsvFile in $CsvFiles) {
        $SanitizedCsvName = ($CsvFile.BaseName -replace "[^\w]", "").ToLower()

        # Find corresponding template by cleaning its name
        $Template = $Templates | Where-Object {
            ($_.TemplateName -replace "[^\w]", "").ToLower() -eq $SanitizedCsvName
        }

        if (-not $Template) {
            Write-Log "⚠️ No matching template found for CSV: $CsvFile (Sanitized: $SanitizedCsvName). Skipping." -Level "WARN"
            continue
        }

        Write-Log "✅ Matched CSV: $CsvFile -> Template: $($Template.TemplateName)" -Level "INFO"

        # Read CSV and check for empty data
        $CsvData = Import-Csv -Path $CsvFile.FullName
        if (-not $CsvData -or $CsvData.Count -eq 0) {
            Write-Log "⚠️ Skipping CSV: $CsvFile (Only headers, no data)" -Level "WARN"
            continue
        }

        # Extract and clean CSV field headers (strip ' - REQUIRED - TYPE')
        $CleanHeaders = @{}
        foreach ($Column in $CsvData[0].PSObject.Properties.Name) {
            $OriginalHeader = $Column
            $CleanHeader = $Column -replace " - REQUIRED - .*", ""  # Remove "- REQUIRED - TYPE"
            $CleanHeaders[$OriginalHeader] = $CleanHeader
        }

        # Process each row in CSV
        foreach ($Row in $CsvData) {
            if (-not $Row.'Secret Name - REQUIRED - TEXT' -or -not $Row.'Folder Path - REQUIRED - TEXT') {
                Write-Log "⚠️ Skipping row due to missing 'Secret Name' or 'Folder Path' in $CsvFile" -Level "WARN"
                Write-Log "❓ Row Content: $($Row | Out-String)" -Level "DEBUG"
                continue
            }

            # Create <Secret> Node
            $SecretNode = $XmlDocument.CreateElement("Secret")
            $SecretsNode.AppendChild($SecretNode) | Out-Null

            # Add <SecretName>
            $SecretNameNode = $XmlDocument.CreateElement("SecretName")
            $SecretNameNode.InnerText = $Row.'Secret Name - REQUIRED - TEXT'
            $SecretNode.AppendChild($SecretNameNode) | Out-Null

            # Add <SecretTemplateName>
            $TemplateNode = $XmlDocument.CreateElement("SecretTemplateName")
            $TemplateNode.InnerText = $Template.TemplateName
            $SecretNode.AppendChild($TemplateNode) | Out-Null

            # Add <FolderPath>
            $FolderPathNode = $XmlDocument.CreateElement("FolderPath")
            $FolderPathNode.InnerText = $Row.'Folder Path - REQUIRED - TEXT'
            $SecretNode.AppendChild($FolderPathNode) | Out-Null

            # Create <SecretItems> Node
            $SecretItemsNode = $XmlDocument.CreateElement("SecretItems")
            $SecretNode.AppendChild($SecretItemsNode) | Out-Null

            # Loop through all fields dynamically
            foreach ($Field in $Template.Fields) {
                $FieldName = $Field.Name
                $MatchingColumn = $CleanHeaders.Keys | Where-Object { $CleanHeaders[$_] -eq $FieldName }

                if ($MatchingColumn) {
                    $FieldValue = $Row.$MatchingColumn

                    if (-not [string]::IsNullOrWhiteSpace($FieldValue)) {
                        # Create <SecretItem> Node
                        $SecretItemNode = $XmlDocument.CreateElement("SecretItem")
                        $SecretItemsNode.AppendChild($SecretItemNode) | Out-Null

                        # Add <FieldName>
                        $FieldNameNode = $XmlDocument.CreateElement("FieldName")
                        $FieldNameNode.InnerText = $FieldName
                        $SecretItemNode.AppendChild($FieldNameNode) | Out-Null

                        # Add <Value>
                        $ValueNode = $XmlDocument.CreateElement("Value")
                        $ValueNode.InnerText = $FieldValue
                        $SecretItemNode.AppendChild($ValueNode) | Out-Null
                    }
                }
            }

            Write-Log "✅ Processed Secret: $($Row.'Secret Name - REQUIRED - TEXT')" -Level "INFO"
            $SecretCount++
        }
    }

    if ($SecretCount -eq 0) {
        Write-Log "⚠️ No secrets were processed. XML file will not be created." -Level "WARN"
        exit 0
    }

    # Save XML to file
    $XmlDocument.Save($XmlOutputFile)
    Write-Log "✅ XML Export Completed: $XmlOutputFile" -Level "INFO"
    Write-Host "✅ XML Export Completed: $XmlOutputFile" -ForegroundColor Green
}

###############################################################################
# FUNCTION: Convert Folder Paths from CSVs to XML for Folder creation
###############################################################################
Function Convert-FoldersToXML {
    Write-Host "📂 Converting all CSV Folder Paths to XML..." -ForegroundColor Yellow

    # Use predefined paths
    $CsvDir = $CsvOutputDir
    $XmlOutputFile = "$XmlOutputDir\Folders.xml"

    # Validate Paths Before Execution
    if (-not (Test-Path $CsvDir)) {
        Write-Log "❌ ERROR: CSV Directory not found: $CsvDir" -Level "ERROR"
        exit 1
    }

    # Initialize XML Document
    $XmlDocument = New-Object System.Xml.XmlDocument
    $XmlDeclaration = $XmlDocument.CreateXmlDeclaration("1.0", "utf-16", $null)
    $XmlDocument.AppendChild($XmlDeclaration) | Out-Null

    # Root XML Node: <ImportFile>
    $ImportFileNode = $XmlDocument.CreateElement("ImportFile")
    $XmlDocument.AppendChild($ImportFileNode) | Out-Null

    # Create <Folders> Node
    $FoldersNode = $XmlDocument.CreateElement("Folders")
    $ImportFileNode.AppendChild($FoldersNode) | Out-Null

    # Collect all folder paths from CSVs
    $FolderPaths = @()
    $CsvFiles = Get-ChildItem -Path $CsvDir -Filter "*.csv"

    foreach ($CsvFile in $CsvFiles) {
        $CsvData = Import-Csv -Path $CsvFile.FullName

        # Skip CSVs that have only headers
        if (-not $CsvData -or $CsvData.Count -eq 0) {
            Write-Log "⚠️ Skipping empty CSV file: $CsvFile" -Level "WARN"
            continue
        }

        # Extract Folder Paths
        foreach ($Row in $CsvData) {
            $FolderPath = $Row.'Folder Path - REQUIRED - TEXT'
            if ($FolderPath -and $FolderPath -notin $FolderPaths) {
                $FolderPaths += $FolderPath
            }
        }
    }

    # Create a set of ALL required folders, including parents
    $AllFolders = @{}
    foreach ($Path in $FolderPaths) {
        $Parts = $Path -split '\\'
        for ($i = 0; $i -lt $Parts.Count; $i++) {
            $SubPath = ($Parts[0..$i] -join '\')
            if (-not $AllFolders.ContainsKey($SubPath)) {
                $AllFolders[$SubPath] = $Parts[$i]  # Store Folder Name
            }
        }
    }

    # Ensure folders are sorted by hierarchy depth
    $SortedFolders = $AllFolders.Keys | Sort-Object { $_ -split '\\' }

    # Process each folder and add it to XML
    foreach ($FolderPath in $SortedFolders) {
        $FolderName = $AllFolders[$FolderPath]  # Get Folder Name

        # Create <Folder> Node
        $FolderNode = $XmlDocument.CreateElement("Folder")
        $FoldersNode.AppendChild($FolderNode) | Out-Null

        # Add <FolderName>
        $FolderNameNode = $XmlDocument.CreateElement("FolderName")
        $FolderNameNode.InnerText = $FolderName
        $FolderNode.AppendChild($FolderNameNode) | Out-Null

        # Add <FolderPath>
        $FolderPathNode = $XmlDocument.CreateElement("FolderPath")
        $FolderPathNode.InnerText = $FolderPath
        $FolderNode.AppendChild($FolderPathNode) | Out-Null

        # Add empty <Permissions> (for inheritance)
        $PermissionsNode = $XmlDocument.CreateElement("Permissions")
        $FolderNode.AppendChild($PermissionsNode) | Out-Null

        Write-Log "✅ Processed Folder: $FolderPath" -Level "INFO"
    }

    if ($SortedFolders.Count -eq 0) {
        Write-Log "⚠️ No folders were processed. XML file will not be created." -Level "WARN"
        exit 0
    }

    # Save XML to file
    $XmlDocument.Save($XmlOutputFile)
    Write-Log "✅ Folder XML Export Completed: $XmlOutputFile" -Level "INFO"
    Write-Host "✅ Folder XML Export Completed: $XmlOutputFile" -ForegroundColor Green
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
