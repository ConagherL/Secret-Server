# Secret Server Migration Cleanup Tools

This directory contains PowerShell scripts and SQL queries designed to help identify and clean up duplicate secrets after a Secret Server migration.

## Overview

During Secret Server migrations, it's common to encounter situations where secrets may be duplicated or not properly mapped between source and destination systems. These tools help identify such issues and provide automated cleanup capabilities.

## Files in this Directory

### Scripts

- **`Compare_All_Secrets.ps1`** - Main comparison and analysis script
- **`Delete_Secrets.ps1`** - Script to deactivate secrets based on a list of IDs
- **`All_Secrets.sql`** - SQL query to export all active secrets from Secret Server database

### Configuration Files (You Need to Create)

- **`Secret_IDs_Mapping.csv`** - CSV file containing the mapping between old and new secret IDs
- **`Source.csv`** - CSV export of secrets from the source system
- **`Destination.csv`** - CSV export of secrets from the destination system

## Quick Start Guide

### Step 1: Export Secret Data

1. **Run the SQL Query**: Execute `All_Secrets.sql` against both your source and destination Secret Server databases

   ```sql
   -- Run this against SOURCE database, save as Source.csv
   -- Run this against DESTINATION database, save as Destination.csv
   ```

2. **Prepare Mapping File**: Create `Secret_IDs_Mapping.csv` with columns:

   ```csv
   OldId,NewId
   123,456
   124,457
   ```

### Step 2: Analyze for Duplicates

1. **Edit File Paths**: Open `Compare_All_Secrets.ps1` and update these paths at the top:
   ```powershell
   $MappingFile = "C:\temp\logs\Secret_IDs_Mapping.csv"
   $SourceFile = "C:\temp\logs\Source.csv"
   $DestinationFile = "C:\temp\logs\Destination.csv"
   $OutputReport = "C:\temp\logs\Secret_Comparison_Report.csv"
   $OutputSummary = "C:\temp\logs\Secret_Comparison_Summary.txt"
   $OutputDeactivateList = "C:\temp\logs\Secrets_To_Deactivate.csv"
   ```

2. **Run Analysis**:
   ```powershell
   .\Compare_All_Secrets.ps1
   ```

### Step 3: Review Results

The script generates three output files:

1. **Detailed Report** (`Secret_Comparison_Report.csv`): Complete analysis of all secrets
2. **Summary** (`Secret_Comparison_Summary.txt`): High-level statistics and counts
3. **Deactivation List** (`Secrets_To_Deactivate.csv`): Secrets recommended for cleanup

### Step 4: Clean Up Duplicates (Optional)

1. **Review the deactivation list carefully** before proceeding
2. **Edit `Delete_Secrets.ps1`** and update these settings:
   ```powershell
   $BaseUrl = 'https://YOURSSURL'
   $IdListPath = 'C:\temp\Logs\SecretIDs.csv'  # Point to your deactivation list
   $LogPath = 'C:\temp\Logs\Deactivate-Secrets.log'
   ```

3. **Run Cleanup**:
   ```powershell
   .\Delete_Secrets.ps1
   ```

## Detailed Script Documentation

### Compare_All_Secrets.ps1

**Purpose**: Analyzes three CSV files to identify migration issues and potential duplicates.

**Input Files**:
- Mapping file with old-to-new ID relationships
- Source system secret export
- Destination system secret export

**Analysis Categories**:
- ✅ **Good Migrations**: Secrets properly mapped and migrated
- ❌ **Not Migrated**: Source secrets missing from destination
- ❌ **Potential Duplicates**: Destination secrets not in mapping but match source
- ⚠️ **SSC-Only Secrets**: Secrets only in destination (manually created?)
- ⚠️ **Mapping Issues**: Various mapping inconsistencies

**Key Features**:
- Compares secrets by Name + Folder Path + Template Name
- Handles multiple matches gracefully
- Generates actionable deactivation lists
- Provides detailed logging and statistics

### Delete_Secrets.ps1

**Purpose**: Safely deactivates secrets from Secret Server using REST API.

**Key Features**:
- OAuth2 authentication with Secret Server
- Supports CSV or plain text ID lists
- Detailed logging of all operations
- Retrieves secret details before deactivation
- Bypasses checkout locks with force parameters
- Comprehensive error handling

**Input Format**:
```csv
SecretID
123
456
789
```
or plain text file with one ID per line.

**Safety Features**:
- Logs all operations with timestamps
- Captures secret names and folder paths before deletion
- Provides success/failure summary
- Color-coded console output

### All_Secrets.sql

**Purpose**: Exports comprehensive secret information from Secret Server database.

**Output Columns**:
- `SecretID`: Unique identifier
- `SecretName`: Display name
- `FolderPath`: Full folder hierarchy
- `TemplateName`: Secret template used
- `CreatedDate`: When secret was created
- `LastModifiedDate`: Last modification timestamp
- `HasFiles`: Whether secret contains file attachments

**Notes**:
- Only returns active (non-deleted) secrets
- Optimized for performance with proper joins
- Handles secrets without folders gracefully

## Common Use Cases

### 1. Post-Migration Cleanup
After migrating from one Secret Server to another, use these tools to:
- Verify all secrets migrated correctly
- Identify and remove duplicates
- Clean up test/temporary secrets

### 2. System Consolidation
When merging multiple Secret Server instances:
- Compare secret inventories
- Identify overlapping secrets
- Implement cleanup strategy

### 3. Audit and Compliance
For regular maintenance:
- Generate secret inventory reports
- Identify orphaned or unused secrets
- Maintain clean folder structure

## Prerequisites

### Software Requirements
- PowerShell 5.1 or later
- Secret Server with REST API enabled
- SQL Server access (for running queries)
- Appropriate Secret Server permissions (View, Edit, Delete secrets)

### File Structure
```
C:\temp\logs\
├── Secret_IDs_Mapping.csv
├── Source.csv
├── Destination.csv
├── Secret_Comparison_Report.csv      (generated)
├── Secret_Comparison_Summary.txt     (generated)
├── Secrets_To_Deactivate.csv        (generated)
└── Deactivate-Secrets.log           (generated)
```

## Security Considerations

- **Credentials**: Scripts prompt for credentials; never hardcode passwords
- **Permissions**: Ensure service accounts have minimal required permissions
- **Logging**: Log files may contain sensitive secret names and paths
- **Backup**: Always backup before running cleanup operations
- **Testing**: Test on non-production environments first

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify Secret Server URL is correct
   - Check user permissions
   - Ensure OAuth2 is enabled

2. **File Not Found Errors**
   - Verify all CSV file paths exist
   - Check file permissions
   - Ensure CSV headers match expected format

3. **API Rate Limiting**
   - Script includes automatic retry logic
   - Consider adding delays for large operations


### Debug Mode
Add this to scripts for verbose logging:
```powershell
$VerbosePreference = 'Continue'
$DebugPreference = 'Continue'
```

## Best Practices

1. **Always Backup** before running cleanup operations
2. **Test First** on a small subset of secrets
3. **Review Reports** carefully before proceeding with cleanup
4. **Monitor Logs** during execution for any errors
5. **Validate Results** after cleanup is complete

## Support

For issues or questions:
1. Check the generated log files for detailed error messages
2. Verify all prerequisites are met
3. Test with a small dataset first
4. Review Secret Server API documentation for authentication issues

---

**⚠️ Warning**: These scripts can permanently delete/deactivate secrets. Always test in a non-production environment first and maintain proper backups.

**📝 Note**: Modify file paths in the scripts to match your environment before running.