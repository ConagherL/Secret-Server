# Deactivate-Secrets.ps1
# ---------------------------------------------------------------------------
# Static Configuration
# ---------------------------------------------------------------------------
$BaseUrl    = 'https://YOURSSURL'
$IdListPath = 'C:\temp\Logs\SecretIDs.csv'
$LogPath    = 'C:\temp\Logs\Deactivate-Secrets.log'

# Auto-generate URLs
$TokenUrl = "$BaseUrl/oauth2/token"
$ApiUrl   = "$BaseUrl/api/v1"

# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

function Write-Log {
    param([string]$Level, [string]$Message)
    $line = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $LogPath -Value $line
    
    $color = switch ($Level) {
        'ERROR'   { 'Red' }
        'SUCCESS' { 'Green' }
        default   { 'Cyan' }
    }
    Write-Host $line -ForegroundColor $color
}

New-Item -ItemType File -Path $LogPath -Force | Out-Null
Write-Log INFO "---- START ----"
Write-Log INFO "BaseUrl=$BaseUrl | IdList=$IdListPath"

# ---------------------------------------------------------------------------
# Authentication
# ---------------------------------------------------------------------------
try {
    $cred = Get-Credential -Message "Secret Server credentials"
    $body = @{
        grant_type = 'password'
        username   = $cred.UserName
        password   = $cred.GetNetworkCredential().Password
    }
    
    $token = (Invoke-RestMethod -Method Post -Uri $TokenUrl -Body $body -ContentType 'application/x-www-form-urlencoded').access_token
    if (-not $token) { throw "No access token received" }
    
    Write-Log SUCCESS "Authenticated"
}
catch {
    Write-Log ERROR "Auth failed: $($_.Exception.Message)"
    exit 1
}

$Headers = @{ Authorization = "Bearer $token" }

# ---------------------------------------------------------------------------
# Load IDs
# ---------------------------------------------------------------------------
try {
    if (-not (Test-Path $IdListPath)) { throw "File not found: $IdListPath" }
    
    $ext = [IO.Path]::GetExtension($IdListPath).ToLowerInvariant()
    
    if ($ext -eq '.csv') {
        $SecretIds = (Import-Csv $IdListPath | Where-Object { $_.SecretID -as [int] } | ForEach-Object { [int]$_.SecretID })
    }
    else {
        $SecretIds = Get-Content $IdListPath | Where-Object { $_ -match '^\s*\d+\s*$' } | ForEach-Object { [int]$_.Trim() }
    }
    
    if (-not $SecretIds) { throw "No valid IDs found" }
    Write-Log INFO "Loaded $($SecretIds.Count) IDs"
}
catch {
    Write-Log ERROR "Failed to load IDs: $($_.Exception.Message)"
    exit 1
}

# ---------------------------------------------------------------------------
# Deactivate Secrets
# ---------------------------------------------------------------------------
$results = foreach ($id in $SecretIds) {
    try {
        # Get secret details first
        $secret = Invoke-RestMethod -Method Get -Uri "$ApiUrl/secrets/$id" -Headers $Headers
        $name = $secret.name
        $template = $secret.secretTemplateName
        
        # Get folder path if folderId exists
        $folder = ""
        if ($secret.folderId -and $secret.folderId -gt 0) {
            try {
                $folderInfo = Invoke-RestMethod -Method Get -Uri "$ApiUrl/folders/$($secret.folderId)" -Headers $Headers
                $folder = $folderInfo.folderPath
            }
            catch {
                $folder = "FolderID: $($secret.folderId)"
            }
        }
        
        # Deactivate with forceCheckIn and autoCheckout to bypass any locks
        Invoke-RestMethod -Method Delete -Uri "$ApiUrl/secrets/$id`?forceCheckIn=true&autoCheckout=true" -Headers $Headers | Out-Null
        Write-Log SUCCESS "Deactivated: $id | Name: $name | Folder: $folder | Template: $template"
        
        [PSCustomObject]@{ 
            SecretId = $id
            Name = $name
            FolderPath = $folder
            Template = $template
            Status = 'Deactivated'
            Error = $null 
        }
    }
    catch {
        Write-Log ERROR "Failed: $id - $($_.Exception.Message)"
        [PSCustomObject]@{ 
            SecretId = $id
            Name = $null
            FolderPath = $null
            Template = $null
            Status = 'Failed'
            Error = $_.Exception.Message 
        }
    }
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$ok = ($results | Where-Object Status -eq 'Deactivated').Count
$bad = ($results | Where-Object Status -ne 'Deactivated').Count
Write-Log INFO "Complete. Success=$ok Failed=$bad"
Write-Log INFO "---- END ----"
