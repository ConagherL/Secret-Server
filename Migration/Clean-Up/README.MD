# Secret Server Cleanup Script

This PowerShell script helps administrators clean up Secret Server environments by:

* Trimming leading/trailing whitespace from **folder** and **secret** names
* Identifying and renaming **duplicate secrets**
* Generating logs and CSV reports for all changes

## Features

* Supports Secret Server Cloud (v1 and v2 API endpoints)
* OAuth2 password grant authentication
* Exported CSVs for auditability
* Log file with color-coded output (green = success, red = error)

---

## Requirements

* PowerShell 5.1 or later
* API credentials to Secret Server with rights to read/update folders and secrets

---

## Configuration

Edit the following variables at the top of the script:

```powershell
# --- CONFIGURATION ---
$BaseUrl        = "https://XXXXXXXXXXX.secretservercloud.com"   # Your Secret Server base URL
$TokenUrl       = "$BaseUrl/oauth2/token"                        # OAuth2 token endpoint
$FixDuplicates  = $true                                           # Enable duplicate secret renaming
$FixWhitespace  = $true                                           # Enable trimming whitespace from names
$OutputPath     = "C:\temp\SecretServerCleanup"                 # Directory for logs/CSVs
$LogFile        = "$OutputPath\SS_Cleanup.log"
$CsvSecretFile  = "$OutputPath\UpdatedSecrets.csv"
$CsvWhitespaceFile_Folders = "$OutputPath\WhitespaceFixes_Folders.csv"
$CsvWhitespaceFile_Secrets = "$OutputPath\WhitespaceFixes_Secrets.csv"
```

---

## Usage

1. Save the script and open in PowerShell.
2. Run the script:

```powershell
.\SecretServer_Cleanup.ps1
```

3. Enter your **Secret Server username** and **password** when prompted.
4. Review output in:

   * Log file: `SS_Cleanup.log`
   * CSVs:

     * `UpdatedSecrets.csv`
     * `WhitespaceFixes_Folders.csv`
     * `WhitespaceFixes_Secrets.csv`

---

## Behavior Details

### Order of Execution

1. Find and fix **whitespace in folders**
2. Find and fix **whitespace in secrets**
3. Find and rename **duplicate secrets** (appends `-1`, `-2`, etc.)

---

## Output

Each operation is logged with color-coded console output:

* ✅ Green: successful updates
* ❌ Red: failed updates

CSV files provide audit trails for all changes performed.

---

## Disclaimer

This script is provided as-is and should be tested in a non-production environment before running in production.