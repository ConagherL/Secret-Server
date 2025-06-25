<#
.SYNOPSIS
Script to migrate reports from a source Secret Server tenant to a destination tenant.

.DESCRIPTION
This script automates the migration of reports from one Secret Server tenant to another.
It handles categories, reports, and ensures no duplicates are created in the destination tenant.
The script includes robust logging and error handling to facilitate a smooth migration process.

.PARAMETER sourceRootUrl
The root URL of the source Secret Server tenant (e.g., 'source.secretservercloud.com').

.PARAMETER destinationRootUrl
The root URL of the destination Secret Server tenant (e.g., 'destination.secretservercloud.com').

.PARAMETER outputDirectory
The directory where report JSON files and logs will be saved.

.EXAMPLE
# Run the script with default settings.
.\Migrate_Reports.ps1

#>

# Customizable Variables
$sourceRootUrl       = 'XXX.com/Secret_Server_PROD'       # Source tenant root URL
$destinationRootUrl  = 'XXXX.secretservercloud.com'       # Destination tenant root URL
$outputDirectory     = 'C:\temp\SQL_Reports'           # Directory for saving report details and logs
$logFilePath         = Join-Path $outputDirectory 'SQL_Report_Migration.log'

# Ensure the log file exists or create with header
if (-not (Test-Path -Path $logFilePath)) {
    New-Item -Path $logFilePath -ItemType File -Force | Out-Null
    Add-Content -Path $logFilePath -Value "Migration Log - $(Get-Date)"
    Add-Content -Path $logFilePath -Value "----------------------------------------`n"
} else {
    Add-Content -Path $logFilePath -Value "`nMigration Log Continued - $(Get-Date)"
    Add-Content -Path $logFilePath -Value "----------------------------------------`n"
}

# Function to log messages to both console and log file
function Write-LogEntry {
    param (
        [string]$Message,
        [ConsoleColor]$Color = [ConsoleColor]::White
    )
    Write-Host $Message -ForegroundColor $Color
    Add-Content -Path $logFilePath -Value $Message
}

# Function to authenticate with a tenant and get an access token
function Connect-Tenant {
    param (
        [string]$tenantName,
        [string]$tokenUrl
    )
    $credential = Get-Credential -Message "Enter your username and password for the $tenantName tenant"
    $username   = $credential.UserName
    $password   = $credential.GetNetworkCredential().Password

    $tokenRequestBody = @{ grant_type = 'password'; username = $username; password = $password }
    $tokenResponse    = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $tokenRequestBody -ContentType 'application/x-www-form-urlencoded'

    if ($tokenResponse -and $tokenResponse.access_token) {
        $accessToken = $tokenResponse.access_token
        Write-LogEntry "Authentication with $tenantName tenant successful." ([ConsoleColor]::Green)
        return @{ Headers = @{ 'Authorization' = "Bearer $accessToken"; 'Content-Type' = 'application/json' } }
    } else {
        Write-LogEntry "Failed to authenticate with $tenantName tenant." ([ConsoleColor]::Red)
        Write-LogEntry "Response: $($tokenResponse | ConvertTo-Json -Depth 5)"
        Exit
    }
}

# Function to fetch all categories from a tenant
function Get-Categories {
    param (
        [string]$apiUrl,
        [hashtable]$headers
    )
    $categoriesUrl = "${apiUrl}/v1/reports/categories"
    return Invoke-RestMethod -Method Get -Uri $categoriesUrl -Headers $headers
}

# Function to create a category in the destination tenant
function New-Category {
    param (
        [string]$apiUrl,
        [hashtable]$headers,
        [object]$sourceCategory
    )
    Write-LogEntry "Creating category '$($sourceCategory.name)' in the destination tenant..."
    $body = @{ data = @{ reportCategoryName = $sourceCategory.name; reportCategoryDescription = $sourceCategory.description; sortOrder = 0 } }
    $json = $body | ConvertTo-Json -Depth 10
    $url  = "${apiUrl}/v1/reports/categories"
    try {
        $resp = Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $json -ContentType 'application/json'
        $dest = @{ id = $resp.data.id; name = $resp.data.name; description = $resp.data.description }
        Write-LogEntry "Category '$($sourceCategory.name)' created with ID $($dest.id)." ([ConsoleColor]::Green)
        return $dest
    } catch {
        Write-LogEntry "Failed to create category '$($sourceCategory.name)'." ([ConsoleColor]::Red)
        Write-LogEntry "Error: $_"
        if ($_.Exception.Response -and $_.Exception.Response.Content) {
            try { $content = $_.Exception.Response.Content.ReadAsStringAsync().Result; Write-LogEntry "Response Body: $content" } catch { Write-LogEntry "Unable to read response content." }
        } else { Write-LogEntry "No response body available." }
        Exit
    }
}

# Function to fetch all reports from a tenant
function Get-AllReports {
    param (
        [string]$apiUrl,
        [hashtable]$headers
    )
    $all     = @()
    $take    = 100
    $skip    = 0
    $total   = 1
    while ($skip -lt $total) {
        $url  = "${apiUrl}/v1/reports?skip=$skip&take=$take"
        $resp = Invoke-RestMethod -Method Get -Uri $url -Headers $headers
        if ($resp.success -and $resp.records) {
            $all += $resp.records
        } else {
            Write-LogEntry "Failed to fetch reports from '$apiUrl'." ([ConsoleColor]::Red)
            Write-LogEntry "Response: $($resp | ConvertTo-Json -Depth 10)"
            break
        }
        $total = $resp.total
        $skip += $take
    }
    return $all
}

# Function to fetch report details
function Get-ReportDetails {
    param (
        [string]$apiUrl,
        [hashtable]$headers,
        [int]$reportId
    )
    $url = "${apiUrl}/v1/reports/$reportId"
    try {
        return Invoke-RestMethod -Method Get -Uri $url -Headers $headers
    } catch {
        Write-LogEntry "Error fetching details for report ID $reportId : $_" ([ConsoleColor]::Red)
        return $null
    }
}

# Function to save report details to JSON file
function Save-ReportToFile {
    param (
        [object]$reportDetails,
        [int]$reportId
    )
    $name    = $reportDetails.name
    $invalid             = [System.IO.Path]::GetInvalidFileNameChars()
    $escapedInvalidChars = [Regex]::Escape(($invalid -join ''))
    $pattern             = "[{0}]" -f $escapedInvalidChars
    $clean               = $name -replace $pattern, ''
}

# Function to create a report in the destination tenant
function New-Report {
    param (
        [string]$apiUrl,
        [hashtable]$headers,
        [object]$reportData
    )
    $json = $reportData | ConvertTo-Json -Depth 10
    $url  = "${apiUrl}/v1/reports"
    Write-LogEntry "Creating report '$($reportData.name)' in the destination tenant..."
    try {
        Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $json -ContentType 'application/json' | Out-Null
        Write-LogEntry "Successfully created report '$($reportData.name)'." ([ConsoleColor]::Green)
    } catch {
        Write-LogEntry "Failed to create report '$($reportData.name)'." ([ConsoleColor]::Red)
        Write-LogEntry "Error: $_"
        if ($_.Exception.Response -and $_.Exception.Response.Content) {
            try {
                $content = $_.Exception.Response.Content.ReadAsStringAsync().Result
                $errFile = [IO.Path]::Combine($outputDirectory, "Error_${($reportData.name)}.txt")
                [System.IO.File]::WriteAllText($errFile, $content, [System.Text.Encoding]::UTF8)
                Write-LogEntry "Error details saved to '$errFile'."
            } catch {
                Write-LogEntry "Unable to read response content."
            }
        } else {
            Write-LogEntry "No response body available."
        }
    }
}

# Function to ensure categories exist in destination
function Set-Categories {
    param (
        [string]$apiSource,
        [string]$apiDestination,
        [hashtable]$headersSource,
        [hashtable]$headersDestination,
        [array]$categoryIds
    )
    Write-LogEntry "Fetching categories from the source tenant..."
    $srcCats = Get-Categories -apiUrl $apiSource -headers $headersSource
    Write-LogEntry "Source categories count: $($srcCats.Count)"
    if ($categoryIds.Count -gt 0) { $srcCats = $srcCats | Where-Object { $categoryIds -contains $_.id } }
    Write-LogEntry "Fetching categories from the destination tenant..."
    $dstCats = Get-Categories -apiUrl $apiDestination -headers $headersDestination
    Write-LogEntry "Destination categories count: $($dstCats.Count)"
    $map = @{}
    foreach ($src in $srcCats) {
        $match = $dstCats | Where-Object { $_.name.ToLower() -eq $src.name.ToLower() }
        if (-not $match) {
            $dest = New-Category -apiUrl $apiDestination -headers $headersDestination -sourceCategory $src
            Write-LogEntry "Created new category: $($src.name)"
        } else {
            Write-LogEntry "Category '$($src.name)' already exists." ([ConsoleColor]::Yellow)
            $dest = $match
        }
        $map[$src.id] = $dest.id
    }
    Write-LogEntry "Re-fetching destination categories..."
    $dstCats = Get-Categories -apiUrl $apiDestination -headers $headersDestination
    foreach ($src in $srcCats) {
        $match = $dstCats | Where-Object { $_.name.ToLower() -eq $src.name.ToLower() }
        if ($match) { $map[$src.id] = $match.id }
    }
    return $map
}

# Function to process and migrate reports
function Set-Reports {
    param (
        [string]$apiSource,
        [string]$apiDestination,
        [hashtable]$headersSource,
        [hashtable]$headersDestination,
        [array]$categoryIds,
        [hashtable]$categoryIdMap,
        [array]$reportIds
    )
    foreach ($id in $reportIds) {
        Write-LogEntry "`nProcessing report ID $id..."
        $details = Get-ReportDetails -apiUrl $apiSource -headers $headersSource -reportId $id
        if (-not $details) { continue }
        Write-LogEntry "Downloaded report ID $id : $($details.name)"
        Save-ReportToFile -reportDetails $details -reportId $id
        $data = $details | Select-Object -ExcludeProperty id, systemReport, createdBy, createdDate, modifiedBy, modifiedDate
        if ($categoryIdMap.ContainsKey($data.categoryId)) {
            $data.categoryId = [int]$categoryIdMap[$data.categoryId]
        } else {
            Write-LogEntry "Category ID $($data.categoryId) not in map. Skipping." ([ConsoleColor]::Yellow)
            continue
        }
        $body = @{ name=$data.name; description=$data.description; categoryId=$data.categoryId; enabled=$data.enabled; reportSql=$data.reportSql; chartType=$data.chartType; is3DReport=$data.is3DReport; pageSize=$data.pageSize; useDatabasePaging=$data.useDatabasePaging }
        New-Report -apiUrl $apiDestination -headers $headersDestination -reportData $body
        Write-LogEntry "Completed report ID $id."
    }
    Write-LogEntry "`nAll reports have been processed."
}

# Build URLs and authenticate
$apiSource           = "https://$sourceRootUrl/api"
$apiDestination      = "https://$destinationRootUrl/api"
$tokenUrlSource      = "https://$sourceRootUrl/oauth2/token"
$tokenUrlDestination = "https://$destinationRootUrl/oauth2/token"

$srcAuth              = Connect-Tenant -tenantName "source"      -tokenUrl $tokenUrlSource
$dstAuth              = Connect-Tenant -tenantName "destination" -tokenUrl $tokenUrlDestination
$headersSource        = $srcAuth.Headers
$headersDestination   = $dstAuth.Headers

# Prompt for category processing options
Write-LogEntry ""                                            
Write-LogEntry "Category Processing Options:"                
Write-LogEntry "1. Process a single category ID"          
Write-LogEntry "2. Process multiple category IDs"        
Write-LogEntry "3. Process all categories"               
$categoryChoice       = Read-Host "Enter your choice (1, 2, or 3)"

switch ($categoryChoice) {
    '1' {
        $categoryIdInput = Read-Host "Enter the category ID to process"
        $categoryIds     = @($categoryIdInput.Trim())
    }
    '2' {
        $categoryIdsInput = Read-Host "Enter category IDs separated by commas (e.g., 1,2,3)"
        $categoryIds      = $categoryIdsInput -split ',' | ForEach-Object { $_.Trim() }
    }
    '3' {
        $categoryIds      = @()  # Empty array signifies all categories
    }
    default {
        Write-LogEntry "Invalid choice. Exiting." ([ConsoleColor]::Red)
        Exit
    }
}

# Process categories and get the mapping
$categoryIdMap = Set-Categories -apiSource $apiSource -apiDestination $apiDestination -headersSource $headersSource -headersDestination $headersDestination -categoryIds $categoryIds

# Prompt for report processing options
Write-LogEntry ""                                      
Write-LogEntry "Report Processing Options:"             
Write-LogEntry "1. Process a single report ID"        
Write-LogEntry "2. Process multiple report IDs"      
Write-LogEntry "3. Process all reports"              
$reportChoice         = Read-Host "Enter your choice (1, 2, or 3)"

switch ($reportChoice) {
    '1' {
        $reportIdInput = Read-Host "Enter the report ID to process"
        $reportIds     = @($reportIdInput.Trim())
    }
    '2' {
        $reportIdsInput = Read-Host "Enter report IDs separated by commas (e.g., 221,222,223)"
        $reportIds      = $reportIdsInput -split ',' | ForEach-Object { $_.Trim() }
    }
    '3' {
        Write-LogEntry "Fetching all reports from the source tenant..."
        $sourceReports      = Get-AllReports -apiUrl $apiSource -headers $headersSource
        Write-LogEntry "Number of reports fetched from source tenant: $($sourceReports.Count)"
        Write-LogEntry "Fetching all reports from the destination tenant..."
        $destinationReports = Get-AllReports -apiUrl $apiDestination -headers $headersDestination
        Write-LogEntry "Number of reports fetched from destination tenant: $($destinationReports.Count)"
        $destinationReportNamesHash = @{}
        foreach ($r in $destinationReports) { $destinationReportNamesHash[$r.name.ToLower()] = $true }
        $reportsToMigrate  = $sourceReports | Where-Object { -not $destinationReportNamesHash[$_.name.ToLower()] }
        if ($categoryIds.Count -gt 0) { $reportsToMigrate = $reportsToMigrate | Where-Object { $categoryIds -contains $_.categoryId } }
        Write-LogEntry "Number of reports to migrate: $($reportsToMigrate.Count)"
        $reportIds         = $reportsToMigrate.id
    }
    default {
        Write-LogEntry "Invalid choice. Exiting." ([ConsoleColor]::Red)
        Exit
    }
}

if ($reportIds.Count -eq 0) {
    Write-LogEntry "No new reports to migrate." ([ConsoleColor]::Yellow)
    Exit
}

# Migrate reports
Set-Reports -apiSource $apiSource -apiDestination $apiDestination -headersSource $headersSource -headersDestination $headersDestination -categoryIds $categoryIds -categoryIdMap $categoryIdMap -reportIds $reportIds

# Prompt to delete JSON files
$deleteChoice = Read-Host "Do you want to delete the JSON files saved in '$outputDirectory'? (Y/N)"
if ($deleteChoice -match '^[Yy]$') {
    Remove-Item -Path "${outputDirectory}\*.json" -Force
    Write-LogEntry "All JSON files have been deleted from '$outputDirectory'." ([ConsoleColor]::Green)
} else {
    Write-LogEntry "JSON files were not deleted and remain in '$outputDirectory'."
}

Write-LogEntry "`nMigration process completed. Log file saved at '$logFilePath'."