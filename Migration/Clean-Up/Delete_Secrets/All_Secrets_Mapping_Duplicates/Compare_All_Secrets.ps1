# ===== FILE PATHS - MODIFY THESE =====
$MappingFile = "C:\temp\logs\Secret_IDs_Mapping.csv"
$SourceFile = "C:\temp\logs\Source.csv"
$DestinationFile = "C:\temp\logs\Destination.csv"
$OutputReport = "C:\temp\logs\Secret_Comparison_Report.csv"
$OutputSummary = "C:\temp\logs\Secret_Comparison_Summary.txt"
$OutputDeactivateList = "C:\temp\logs\Secrets_To_Deactivate.csv"
# ======================================

function Import-CSVFiles {
    Write-Host "`nLoading CSV files..." -ForegroundColor Cyan
    
    try {
        $mapping = Import-Csv -Path $MappingFile
        Write-Host "  [OK] Loaded $($mapping.Count) mappings from $MappingFile" -ForegroundColor Green
        
        $source = Import-Csv -Path $SourceFile
        Write-Host "  [OK] Loaded $($source.Count) source secrets from $SourceFile" -ForegroundColor Green
        
        $destination = Import-Csv -Path $DestinationFile
        Write-Host "  [OK] Loaded $($destination.Count) destination secrets from $DestinationFile" -ForegroundColor Green
        
        return @{
            Mapping = $mapping
            Source = $source
            Destination = $destination
        }
    }
    catch {
        Write-Host "  [ERROR] Error loading files: $_" -ForegroundColor Red
        Write-Host "  Please ensure all CSV files are in the same directory as this script." -ForegroundColor Yellow
        exit 1
    }
}

function Format-DateTime {
    param(
        [string]$DateTimeString
    )
    
    if ([string]::IsNullOrWhiteSpace($DateTimeString)) {
        return ""
    }
    
    try {
        $dt = [DateTime]::Parse($DateTimeString)
        return $dt.ToString("yyyy-MM-dd HH:mm:ss")
    }
    catch {
        return $DateTimeString
    }
}

function Get-ComparisonKey {
    param(
        [string]$SecretName,
        [string]$FolderPath,
        [string]$TemplateName
    )
    
    return "$($SecretName.Trim())|$($FolderPath.Trim())|$($TemplateName.Trim())"
}

function Compare-Secrets {
    param(
        $Mapping,
        $Source,
        $Destination
    )
    
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "ANALYZING SECRETS" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    $results = @()
    
    # Create lookup hashtables
    $mappedOldIds = @{}
    $mappedNewIds = @{}
    $oldToNew = @{}
    $newToOld = @{}
    
    foreach ($map in $Mapping) {
        $oldId = [int]$map.OldId
        $newId = [int]$map.NewId
        $mappedOldIds[$oldId] = $true
        $mappedNewIds[$newId] = $true
        $oldToNew[$oldId] = $newId
        $newToOld[$newId] = $oldId
    }
    
    # Create destination lookup by comparison key
    $destByKey = @{}
    foreach ($dest in $Destination) {
        $key = Get-ComparisonKey -SecretName $dest.SecretName -FolderPath $dest.FolderPath -TemplateName $dest.TemplateName
        if (-not $destByKey.ContainsKey($key)) {
            $destByKey[$key] = @()
        }
        $destByKey[$key] += $dest
    }
    
    # Create source lookup by comparison key
    $sourceByKey = @{}
    foreach ($src in $Source) {
        $key = Get-ComparisonKey -SecretName $src.SecretName -FolderPath $src.FolderPath -TemplateName $src.TemplateName
        if (-not $sourceByKey.ContainsKey($key)) {
            $sourceByKey[$key] = @()
        }
        $sourceByKey[$key] += $src
    }
    
    # 1. Analyze SOURCE secrets
    Write-Host "`n1. Analyzing SOURCE secrets..." -ForegroundColor Yellow
    
    foreach ($sourceRow in $Source) {
        $sourceId = [int]$sourceRow.SecretID
        $key = Get-ComparisonKey -SecretName $sourceRow.SecretName -FolderPath $sourceRow.FolderPath -TemplateName $sourceRow.TemplateName
        
        # Check if this source secret was mapped
        $isMapped = $mappedOldIds.ContainsKey($sourceId)
        
        if ($isMapped) {
            # This is a known good migration
            $expectedNewId = $oldToNew[$sourceId]
            $destMatch = $Destination | Where-Object { [int]$_.SecretID -eq $expectedNewId }
            
            if ($destMatch) {
                $status = "[OK] GOOD MIGRATION"
                $issue = $null
            }
            else {
                $status = "[WARN] MAPPED BUT MISSING IN DESTINATION"
                $issue = "Source ID $sourceId mapped to $expectedNewId but not found in destination"
            }
        }
        else {
            # Check if secret exists in destination (by key)
            $destMatches = $destByKey[$key]
            
            if (-not $destMatches) {
                $status = "[ERROR] NOT MIGRATED"
                $issue = "Source ID $sourceId not in mapping and not found in destination"
            }
            else {
                $status = "[WARN] NOT MAPPED BUT EXISTS IN DESTINATION"
                $issue = "Source ID $sourceId not in mapping but found $($destMatches.Count) match(es) in destination"
            }
        }
        
        $results += [PSCustomObject]@{
            SourceID = $sourceId
            DestinationID = if ($oldToNew.ContainsKey($sourceId)) { $oldToNew[$sourceId] } else { $null }
            SecretName = $sourceRow.SecretName
            FolderPath = $sourceRow.FolderPath
            TemplateName = $sourceRow.TemplateName
            Status = $status
            Issue = $issue
            SourceCreatedDate = Format-DateTime -DateTimeString $sourceRow.CreatedDate
            SourceLastModifiedDate = Format-DateTime -DateTimeString $sourceRow.LastModifiedDate
            SourceHasFiles = $sourceRow.HasFiles
        }
    }
    
    # 2. Analyze DESTINATION secrets (find extras/duplicates)
    Write-Host "2. Analyzing DESTINATION secrets for duplicates and extras..." -ForegroundColor Yellow
    
    foreach ($destRow in $Destination) {
        $destId = [int]$destRow.SecretID
        $key = Get-ComparisonKey -SecretName $destRow.SecretName -FolderPath $destRow.FolderPath -TemplateName $destRow.TemplateName
        
        # Skip if this is a known good migration
        if ($mappedNewIds.ContainsKey($destId)) {
            continue
        }
        
        # This destination secret is NOT in the mapping - potential issue
        $sourceMatches = $sourceByKey[$key]
        
        if (-not $sourceMatches) {
            # Secret only exists in destination
            $status = "[WARN] SSC-ONLY SECRET"
            $issue = "Destination ID $destId exists in SSC but not found in source"
        }
        else {
            # Secret exists in source but not mapped - likely a duplicate
            $status = "[ERROR] POTENTIAL DUPLICATE"
            $sourceIds = ($sourceMatches | ForEach-Object { $_.SecretID }) -join ', '
            $issue = "Destination ID $destId matches source ID(s) $sourceIds but is not in mapping"
        }
        
        $results += [PSCustomObject]@{
            SourceID = $null
            DestinationID = $destId
            SecretName = $destRow.SecretName
            FolderPath = $destRow.FolderPath
            TemplateName = $destRow.TemplateName
            Status = $status
            Issue = $issue
            SourceCreatedDate = $null
            SourceLastModifiedDate = $null
            SourceHasFiles = $null
        }
    }
    
    return $results
}

function New-Summary {
    param(
        $Results,
        $Mapping,
        $Source,
        $Destination
    )
    
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "GENERATING SUMMARY" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    $summary = @()
    $summary += "SECRET SERVER MIGRATION COMPARISON REPORT"
    $summary += "=" * 60
    $summary += "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    $summary += ""
    
    $summary += "INPUT FILES:"
    $summary += "  Mapping File:     $MappingFile"
    $summary += "  Source File:      $SourceFile"
    $summary += "  Destination File: $DestinationFile"
    $summary += ""
    
    $summary += "OVERALL STATISTICS:"
    $summary += "  Total Source Secrets:      $($Source.Count)"
    $summary += "  Total Destination Secrets: $($Destination.Count)"
    $summary += "  Total Mapped Secrets:      $($Mapping.Count)"
    $summary += ""
    
    # Count by status
    $goodMigrations = ($Results | Where-Object { $_.Status -eq '[OK] GOOD MIGRATION' }).Count
    $notMigrated = ($Results | Where-Object { $_.Status -eq '[ERROR] NOT MIGRATED' }).Count
    $duplicates = ($Results | Where-Object { $_.Status -eq '[ERROR] POTENTIAL DUPLICATE' }).Count
    $sscOnly = ($Results | Where-Object { $_.Status -eq '[WARN] SSC-ONLY SECRET' }).Count
    $mappedMissing = ($Results | Where-Object { $_.Status -eq '[WARN] MAPPED BUT MISSING IN DESTINATION' }).Count
    $notMappedExists = ($Results | Where-Object { $_.Status -eq '[WARN] NOT MAPPED BUT EXISTS IN DESTINATION' }).Count
    
    $summary += "MIGRATION STATUS BREAKDOWN:"
    $summary += "  [OK]    Good Migrations:                        $goodMigrations"
    $summary += "  [ERROR] Not Migrated:                           $notMigrated"
    $summary += "  [ERROR] Potential Duplicates:                   $duplicates"
    $summary += "  [WARN]  SSC-Only Secrets:                       $sscOnly"
    $summary += "  [WARN]  Mapped but Missing in Destination:      $mappedMissing"
    $summary += "  [WARN]  Not Mapped but Exists in Destination:   $notMappedExists"
    $summary += ""
    
    # Issues requiring attention
    $issues = $Results | Where-Object { $null -ne $_.Issue }
    $summary += "TOTAL ISSUES REQUIRING ATTENTION: $($issues.Count)"
    $summary += ""
    $summary += "NOTE: See detailed report CSV for complete list of issues."
    $summary += ""
    $summary += "="*60
    $summary += "End of Report"
    
    return $summary -join "`n"
}

function New-DeactivationList {
    param(
        $Results
    )
    
    Write-Host "`n============================================================" -ForegroundColor Cyan
    Write-Host "GENERATING DEACTIVATION LIST" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    
    # Secrets that should be deactivated:
    # Any destination secret NOT in the mapping file = duplicate
    # This includes:
    # 1. Potential Duplicates - matches source but not in mapping
    # 2. SSC-Only Secrets - in destination but not in source or mapping
    # 3. Not Mapped but Exists in Destination - possible manual migrations
    
    $toDeactivate = @()
    
    # Get all destination secrets not in the mapping
    $problemSecrets = $Results | Where-Object { 
        $_.Status -eq '[ERROR] POTENTIAL DUPLICATE' -or 
        $_.Status -eq '[WARN] SSC-ONLY SECRET' -or
        $_.Status -eq '[WARN] NOT MAPPED BUT EXISTS IN DESTINATION'
    }
    
    foreach ($secret in $problemSecrets) {
        if ($null -ne $secret.DestinationID) {
            $toDeactivate += [PSCustomObject]@{
                DestinationID = $secret.DestinationID
                SecretName = $secret.SecretName
                FolderPath = $secret.FolderPath
                TemplateName = $secret.TemplateName
                Reason = $secret.Status
                Issue = $secret.Issue
            }
        }
    }
    
    Write-Host "  Found $($toDeactivate.Count) secrets that should be reviewed for deactivation" -ForegroundColor Yellow
    
    return $toDeactivate
}

# ===== MAIN EXECUTION =====

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "SECRET SERVER MIGRATION COMPARISON TOOL" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# Load CSV files
$data = Import-CSVFiles

# Perform analysis
$results = Compare-Secrets -Mapping $data.Mapping -Source $data.Source -Destination $data.Destination

# Generate summary
$summaryText = New-Summary -Results $results -Mapping $data.Mapping -Source $data.Source -Destination $data.Destination

# Generate deactivation list
$deactivationList = New-DeactivationList -Results $results

# Save results
Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "SAVING RESULTS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$results | Export-Csv -Path $OutputReport -NoTypeInformation
Write-Host "  [OK] Detailed report saved to: $OutputReport" -ForegroundColor Green

$summaryText | Out-File -FilePath $OutputSummary -Encoding UTF8
Write-Host "  [OK] Summary saved to: $OutputSummary" -ForegroundColor Green

if ($deactivationList.Count -gt 0) {
    $deactivationList | Export-Csv -Path $OutputDeactivateList -NoTypeInformation
    Write-Host "  [OK] Deactivation list saved to: $OutputDeactivateList" -ForegroundColor Green
    Write-Host "       Review this list before deactivating secrets!" -ForegroundColor Yellow
}
else {
    Write-Host "  [OK] No secrets need deactivation" -ForegroundColor Green
}

# Print summary to console
Write-Host "`n$summaryText" -ForegroundColor White

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "COMPARISON COMPLETE!" -ForegroundColor Cyan
Write-Host "============================================================`n" -ForegroundColor Cyan