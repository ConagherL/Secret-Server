# --- CONFIGURATION ---
$BaseUrl        = "https://XXXXXXXXXXXX.secretservercloud.com"                    # Change this to your Secret Server URL
$TokenUrl       = "$BaseUrl/oauth2/token"                                # OAuth2 token endpoint
$FixDuplicates  = $true                                                  # Enable renaming of secrets with duplicate names
$FixWhitespace  = $true                                             # Enable trimming whitespace from folder/secret names

# COMMENT CONFIGURATION
$UpdateComment = "Automated cleanup: Secret Name Cleanup for Migration"        # Comment used for all secret updates

$OutputPath     = "C:\temp\SecretServerCleanup"
$LogFile        = "$OutputPath\SS_Cleanup.log"
$CsvSecretFile  = "$OutputPath\UpdatedSecrets.csv"
$CsvWhitespaceFile_Folders = "$OutputPath\WhitespaceFixes_Folders.csv"
$CsvWhitespaceFile_Secrets = "$OutputPath\WhitespaceFixes_Secrets.csv"

$global:SecretUpdates  = @()
$global:WhitespaceSecretUpdates = @()
$global:WhitespaceFolderUpdates = @()

# --- LOGGING ---
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = 'INFO'
    )

    $entry = "[$Level] $Message"

    switch ($Level) {
        'INFO'  { Write-Host $entry -ForegroundColor White }
        'ERROR' { Write-Host $entry -ForegroundColor Red }
        'SUCCESS' { Write-Host $entry -ForegroundColor Green }
        'WARNING' { Write-Host $entry -ForegroundColor Yellow }
        default { Write-Host $entry }
    }

    Add-Content -Path $LogFile -Value $entry
}

# --- AUTHENTICATION ---
function Get-AuthToken {
    param([string]$Username, [SecureString]$SecurePassword)

    $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePassword)
    )

    $body = @{
        username   = $Username
        password   = $passwordPlain
        grant_type = "password"
    }

    $response = Invoke-RestMethod -Uri $TokenUrl -Method Post -Body $body -ContentType "application/x-www-form-urlencoded"
    Write-Log "Authentication successful"
    return $response.access_token
}

# --- GET COMMENT FOR UPDATE ---
function Get-UpdateComment {
    return $UpdateComment
}

# --- PAGING HELPER ---
function Get-SSPagedItems {
    param (
        [string]$Endpoint,
        [string]$AuthToken
    )
    $results = @()
    $headers = @{ Authorization = "Bearer $AuthToken" }

    $isFolderRequest = $Endpoint -like "folders*"
    $basePath = if ($isFolderRequest) { "$BaseUrl/api/v1/$Endpoint" } else { "$BaseUrl/api/v2/$Endpoint" }

    for ($skip = 0; ; $skip += 500) {
        $uri = "$basePath&take=500&skip=$skip"

        try {
            $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Get
            if ($null -eq $response.records -or $response.records.Count -eq 0) {
                break
            }

            $results += $response.records
            if ($response.records.Count -lt 500) { break }
        } catch {
            Write-Log "[ERROR] Failed to fetch $Endpoint at skip=$skip : $_" "ERROR"
            break
        }
    }

    return $results
}

# --- UPDATE SECRET NAME WITH COMMENT SUPPORT ---
function Update-SecretName {
    param (
        [int]$SecretId,
        [string]$NewName,
        [string]$OldName,
        [string]$FolderPath,
        [string]$AuthToken,
        [string]$Reason
    )

    $headers = @{ Authorization = "Bearer $AuthToken" }
    $body = @{ data = @{ name = @{ dirty = $true; value = $NewName } } } | ConvertTo-Json -Depth 10

    # Get the comment
    $comment = Get-UpdateComment
    
    # Build URL with comment parameter
    $url = "$BaseUrl/api/v1/secrets/$SecretId/general?autoComment=" + [System.Web.HttpUtility]::UrlEncode($comment)

    try {
        Write-Log "Updating secret ID=$SecretId with comment: '$comment'" "INFO"
        
        Invoke-RestMethod -Uri $url -Method Patch -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
        Write-Log "Updated secret ID=$SecretId to name '$NewName'" "SUCCESS"

        $updateEntry = [PSCustomObject]@{
            SecretId   = $SecretId
            OldName    = $OldName
            NewName    = $NewName
            FolderPath = $FolderPath
            Reason     = $Reason
            Comment    = $comment
        }

        if ($Reason -eq "Whitespace Fix") {
            $global:WhitespaceSecretUpdates += $updateEntry
        } else {
            $global:SecretUpdates += $updateEntry
        }
    } catch {
        Write-Log "[ERROR] Failed to update secret ID=$SecretId to '$NewName': $_" "ERROR"
    }
}

# --- UPDATE FOLDER NAME ---
function Update-FolderName {
    param (
        [int]$FolderId,
        [string]$NewName,
        [string]$OldName,
        [string]$FullPath,
        [string]$AuthToken
    )

    $headers = @{ Authorization = "Bearer $AuthToken" }
    $url = "$BaseUrl/api/v1/folders/$FolderId"
    $body = @{ data = @{ folderName = @{ dirty = $true; value = $NewName } } } | ConvertTo-Json -Depth 10

    try {
        Invoke-RestMethod -Uri $url -Method Patch -Headers $headers -Body $body -ContentType 'application/json' | Out-Null
        Write-Log "Updated folder ID=$FolderId to name '$NewName'" "SUCCESS"

        $updateEntry = [PSCustomObject]@{
            FolderId = $FolderId
            OldName  = $OldName
            NewName  = $NewName
            FullPath = $FullPath
        }
        $global:WhitespaceFolderUpdates += $updateEntry
    } catch {
        Write-Log "[ERROR] Failed to update folder ID=$FolderId to '$NewName': $_" "ERROR"
    }
}

# --- FIND WHITESPACE FOLDERS ---
function Find-WhitespaceFolders {
    param([string]$AuthToken)
    Write-Log "** Finding folders with leading or trailing whitespace in names..."

    $endpoint = "folders?includeSubfolders=true"
    $folders = Get-SSPagedItems -Endpoint $endpoint -AuthToken $AuthToken

    $foldersWithWhitespace = $folders | Where-Object { $_.folderName -match '^\s+|\s+$' }
    Write-Log "Found $($foldersWithWhitespace.Count) folders with whitespace in names"

    foreach ($folder in $foldersWithWhitespace) {
        $trimmedName = $folder.folderName.Trim()
        Write-Log "[WHITESPACE] ID=$($folder.id) '$($folder.folderName)' → '$trimmedName'"

        if ($FixWhitespace) {
            Update-FolderName -FolderId $folder.id -OldName $folder.folderName -NewName $trimmedName -FullPath $folder.folderPath -AuthToken $AuthToken
        }
    }

    if ($global:WhitespaceFolderUpdates.Count -gt 0) {
        $global:WhitespaceFolderUpdates | Export-Csv -Path $CsvWhitespaceFile_Folders -NoTypeInformation -Encoding UTF8
        Write-Log "Exported $($global:WhitespaceFolderUpdates.Count) whitespace-fixed folders to $CsvWhitespaceFile_Folders"
    }
}

# --- FIND WHITESPACE SECRETS ---
function Find-WhitespaceSecrets {
    param([string]$AuthToken)
    Write-Log "** Finding secrets with leading or trailing whitespace in names..."

    $endpoint = "secrets?filter.includeActive=true&filter.includeRestricted=true&filter.permissionRequired=1&filter.scope=All&filter.includeInactive=false"
    $secrets = Get-SSPagedItems -Endpoint $endpoint -AuthToken $AuthToken

    $filtered = $secrets | Select-Object id, name, folderPath
    Write-Log "Total secrets returned from API: $($filtered.Count)"

    $whitespaceSecrets = $filtered | Where-Object { $_.name -match '^\s+|\s+$' }
    Write-Log "Found $($whitespaceSecrets.Count) secrets with whitespace in names"

    foreach ($secret in $whitespaceSecrets) {
        $trimmedName = $secret.name.Trim()
        Write-Log "[WHITESPACE] ID=$($secret.id) '$($secret.name)' → '$trimmedName'"

        if ($FixWhitespace) {
            Update-SecretName -SecretId $secret.id -OldName $secret.name -NewName $trimmedName -FolderPath $secret.folderPath -AuthToken $AuthToken -Reason "Whitespace Fix"
        }
    }

    if ($global:WhitespaceSecretUpdates.Count -gt 0) {
        $global:WhitespaceSecretUpdates | Export-Csv -Path $CsvWhitespaceFile_Secrets -NoTypeInformation -Encoding UTF8
        Write-Log "Exported $($global:WhitespaceSecretUpdates.Count) whitespace-fixed secrets to $CsvWhitespaceFile_Secrets"
    }
}

# --- FIND DUPLICATE SECRETS ---
function Find-DuplicateSecrets {
    param([string]$AuthToken)
    Write-Log "** Finding duplicate secret names..."

    $endpoint = "secrets?filter.includeActive=true&filter.includeRestricted=true&filter.permissionRequired=1&filter.scope=All&filter.includeInactive=false"
    $secrets = Get-SSPagedItems -Endpoint $endpoint -AuthToken $AuthToken

    $filtered = $secrets | Select-Object id, name, folderPath
    Write-Log "Total secrets returned: $($filtered.Count)"

    $nameGroups = $filtered | Group-Object -Property name | Where-Object { $_.Count -gt 1 }
    Write-Log "Found $($nameGroups.Count) secret names with duplicates"

    foreach ($group in $nameGroups) {
        Write-Log "[DUPLICATE] '$($group.Name)' appears $($group.Count) times"

        $groupSorted = $group.Group | Sort-Object id
        for ($i = 1; $i -lt $groupSorted.Count; $i++) {
            $secret = $groupSorted[$i]
            $newName = "$($group.Name)-$i"
            Update-SecretName -SecretId $secret.id -OldName $secret.name -NewName $newName -FolderPath $secret.folderPath -AuthToken $AuthToken -Reason "Duplicate Fix"
        }
    }

    if ($global:SecretUpdates.Count -gt 0) {
        $global:SecretUpdates | Export-Csv -Path $CsvSecretFile -NoTypeInformation -Encoding UTF8
        Write-Log "Exported $($global:SecretUpdates.Count) updated secrets to $CsvSecretFile"
    }
}

# --- MAIN EXECUTION ---
if (-not (Test-Path $OutputPath)) { New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null }

# Load System.Web for URL encoding
Add-Type -AssemblyName System.Web

Write-Log "== Secret Server Cleanup with Comment Support =="
Write-Log "* Base URL: $BaseUrl"
Write-Log "* FixDuplicates = $FixDuplicates"
Write-Log "* FixWhitespace = $FixWhitespace"
Write-Log "* Update Comment: $UpdateComment"

$Username       = Read-Host "Enter your Secret Server username"
$securePassword = Read-Host -AsSecureString "Enter your Secret Server password"
$AuthToken      = Get-AuthToken -Username $Username -SecurePassword $securePassword

if ($FixWhitespace) {
    Find-WhitespaceSecrets -AuthToken $AuthToken
    Find-WhitespaceFolders -AuthToken $AuthToken
}

if ($FixDuplicates) {
    Find-DuplicateSecrets -AuthToken $AuthToken
}

Write-Log "== Cleanup completed =="
