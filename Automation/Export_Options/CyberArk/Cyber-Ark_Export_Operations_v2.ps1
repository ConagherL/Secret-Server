<#
.SYNOPSIS
    Automates the process of retrieving account details and passwords (optional) 
    from CyberArk’s REST API, filtering by a given Safe, and exporting them to a CSV.

.DESCRIPTION
    1. Prompts for CyberArk username/password credentials.
    2. Authenticates via CyberArk’s REST API to obtain a session token.
    3. Retrieves up to the specified limit of accounts (default 500). All accounts are pulled then filtered locally
    4. Filters accounts by the configured Safe name (locally).
    5. For each filtered account, optionally retrieves password (or a fake password) and captures extended details (notes).
    6. Logs all operations (INFO, WARN, ERROR) to console and to a specified log file.
    7. Exports final results to CSV when desired.

.PARAMETER $ExportToFile
    Determines if the collected data is exported to the specified CSV file.

.PARAMETER $ExportPwdField
    Toggles whether the password field is included in the output data.

.PARAMETER $ExportFakePw
    Replaces the real password with a generated placeholder if enabled.

.PARAMETER $CyberArkURL
    The base URL endpoint for CyberArk (e.g., "https://TENANT.privilegecloud.cyberark.com").

.PARAMETER $SafeName
    The Safe name that the script filters accounts on (case-sensitive).

.PARAMETER $OutputFilePath
    Path to the CSV file for export (only used if $ExportToFile is $true).

.PARAMETER $OutputLogPath
    Path to the log file where script events are recorded.

.PARAMETER $Reason
    The reason provided to CyberArk for password retrieval requests.

.EXAMPLE
    .\Export-CyberArkAccounts.ps1
    Prompts for credentials, retrieves accounts from CyberArk, logs progress,
    and exports the data (including optional passwords) to the configured CSV location.

.NOTES
    - Make sure to update $CyberArkURL, $SafeName, and output paths to match your environment.
    - Increase the query limit in $AllAccountsURI if you expect more than 500 accounts.
    - The script requires PowerShell 7 for the -UnixTimeseconds option in Get-Date.

#>

###############################################################################
# Configuration variables
###############################################################################
$ExportToFile   = $true   # Determines if the export should be written to a file
$ExportPwdField = $true   # Specifies whether the password field should be included in the output file
$ExportFakePw   = $true   # Indicates if the actual password should be replaced with a fake-generated password for testing
$CyberArkURL    = "https://TENANT.privilegecloud.cyberark.com"
$SafeName       = "REALSAFENAME"
$OutputFilePath = "C:\temp\export.csv"
$OutputLogPath  = "C:\temp\T_export.log"
$Reason         = "Automation export process"  # Reason for password retrieval

###############################################################################
# 1) Prompt for Credentials
###############################################################################
$Cred = Get-Credential -Message "Enter CyberArk PAM Username and Password"
$Username = $Cred.UserName
$Password = $Cred.GetNetworkCredential().Password

###############################################################################
# Function to generate a random password
###############################################################################
function GenRandomPwd {
    param (
        [Parameter(Mandatory)]
        [int] $length
    )
    $charSet = 'abcdefghijklmnopqrstuvwxyzABCDEFGHJKMNPQRSTUVWXYZ0123456789'.ToCharArray()
    $rng     = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $bytes   = New-Object byte[]($length)
    $rng.GetBytes($bytes)
    $result  = New-Object char[]($length)
    
    for ($i = 0; $i -lt $length; $i++) {
        $result[$i] = $charSet[$bytes[$i] % $charSet.Length]
    }
    return "FakePw-" + -join $result
}

###############################################################################
# Function to write logs
###############################################################################
Function Write-Log {
    param(
        [Parameter(Mandatory = $true)][string] $message,
        [Parameter(Mandatory = $false)][ValidateSet("INFO", "WARN", "ERROR")][string] $level = "INFO"
    )
    # Create timestamp
    $timestamp = (Get-Date).ToString("yyyy/MM/dd HH:mm:ss")
    # Append content to log file
    Add-Content -Path $OutputLogPath -Value "$timestamp [$level] - $message"
    # Print to console for real-time debugging
    Write-Host "$timestamp [$level] - $message"
}

Write-Log -level INFO -message "Starting data retrieval from CyberArk"

$output = @()

###############################################################################
# 1) Authentication
###############################################################################
$RequestBody = @{
    username = $Username
    password = $Password
}
$AuthURI = "$CyberArkURL/PasswordVault/API/Auth/Cyberark/Logon"
try {
    $AuthResponse = Invoke-RestMethod -Uri $AuthURI -Method Post `
        -Body ($RequestBody | ConvertTo-Json) -ContentType "application/json"
    $Token = $AuthResponse
    Write-Log -level INFO -message "Authentication successful"
} catch {
    Write-Log -level ERROR -message "Authentication failed: $($_.Exception.Message)"
    exit
}

$Headers = @{
    "Authorization" = $Token
    "Content-Type"  = "application/json"
}

###############################################################################
# 2) Retrieve ALL accounts (Adjust the limit as needed)
###############################################################################
$AllAccountsURI = "$CyberArkURL/PasswordVault/api/accounts?limit=500"
try {
    $AllAccountsData = Invoke-RestMethod -Uri $AllAccountsURI -Headers $Headers
    Write-Log -level INFO -message "Retrieved $($AllAccountsData.value.Count) accounts without filtering"
} catch {
    Write-Log -level ERROR -message "Failed to retrieve accounts: $($_.Exception.Message)"
    exit
}

###############################################################################
# 3) Filter on SafeName. All accounts from all "Safes" will be pulled and filtered locally based on Safe name.
###############################################################################
$FilteredAccounts = $AllAccountsData.value | Where-Object { $_.safeName -eq $SafeName }
Write-Log -level INFO -message "Retrieved $($FilteredAccounts.Count) accounts from safe '$SafeName'"

if (-not $FilteredAccounts -or $FilteredAccounts.Count -eq 0) {
    Write-Log -level ERROR -message "No accounts retrieved from safe '$SafeName'. Double-check spelling/permissions."
    exit
}

###############################################################################
# 4) Process Each Filtered Account
###############################################################################
foreach ($Account in $FilteredAccounts) {
    $AccountID = $Account.id
    # Basic properties from the list-level data
    $AccountValue = [PSCustomObject]@{
        id          = $Account.id
        name        = $Account.name
        address     = $Account.address
        userName    = $Account.userName
        platformId  = $Account.platformId
        safeName    = $Account.safeName
        #createdTime = (Get-Date -UnixTimeseconds $Account.createdTime -AsUTC)
        $createdTime = [System.DateTimeOffset]::FromUnixTimeSeconds($Account.createdTime).LocalDateTime
    }

    if (-not $AccountValue) {
        Write-Log -level ERROR -message "Unable to parse partial account details for ID: $AccountID"
        continue
    }

    Write-Log -level INFO -message "Processing account ID: $AccountID - $($AccountValue.name)"

    ###############################################################################
    # 4a) Retrieve Additional Details for 'AccountDescription' (aka "Notes")
    ###############################################################################
    $DetailUri = "$CyberArkURL/PasswordVault/api/accounts/$AccountID"
    try {
        $DetailResponse = Invoke-RestMethod -Uri $DetailUri -Method GET -Headers $Headers
        $AccountDescription = $DetailResponse.platformAccountProperties.AccountDescription
    } catch {
        Write-Log -level WARN -message "Failed to retrieve extended details for $AccountID $($_.Exception.Message)"
        $AccountDescription = $null
    }

    ###############################################################################
    # 4b) Retrieve Account Password (if $ExportPwdField = $true)
    ###############################################################################
    $AccountURI = "$CyberArkURL/PasswordVault/api/accounts/$AccountID/Password/Retrieve"
    $PasswordRequestBody = @{ reason = $Reason } | ConvertTo-Json
    try {
        $AccountResponse  = Invoke-RestMethod -Uri $AccountURI -Method POST -Headers $Headers `
            -Body $PasswordRequestBody -ContentType "application/json"
        $AccountPassword  = $AccountResponse
        Write-Log -level INFO -message "Successfully retrieved password for Account ID: $AccountID"
    } catch {
        Write-Log -level ERROR -message "Failed to retrieve password for Account ID: $AccountID - Error: $($_.Exception.Message)"
        continue
    }

    ###############################################################################
    # 4c) Build the object for output/export
    ###############################################################################
    $object = [PSCustomObject]@{
        ID          = $AccountValue.id
        Name        = $AccountValue.name
        Address     = $AccountValue.address
        UserName    = $AccountValue.userName
        PlatformID  = $AccountValue.platformId
        SafeName    = $AccountValue.safeName
        CreatedTime = $AccountValue.createdTime
        Notes       = $AccountDescription

        # Decide which password to store
        Password    = if ($ExportPwdField) {
            if ($ExportFakePw) {
                GenRandomPwd -length 12
            } else {
                $AccountPassword
            }
        } else {
            $null
        }
    }

    $output += $object
}

###############################################################################
# 5) Final Output Count & Export
###############################################################################
Write-Log -level INFO -message "Final number of accounts collected: $($output.Count)"

if ($ExportToFile -and $output.Count -gt 0) {
    try {
        $output | Export-Csv -Path $OutputFilePath -NoTypeInformation
        Write-Log -level INFO -message "Exported data to $OutputFilePath"
    } catch {
        Write-Log -level ERROR -message "Failed to export data to $OutputFilePath $($_.Exception.Message)"
    }
} else {
    Write-Log -level ERROR -message "No data available for export."
}

Write-Log -level INFO -message "Data retrieval from CyberArk completed"
