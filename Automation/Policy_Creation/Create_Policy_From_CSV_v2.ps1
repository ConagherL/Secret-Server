<#
.SYNOPSIS
    Modular script to create/update Secret Server policies from CSV and assign them to folders.
#>

param(
    [string]$BaseUrl      = 'https://yourssurl',
    [string]$CsvPath      = 'C:\temp\Policy_Creation\Policy_Info.csv',
    [string]$LogPath      = 'C:\temp\Policy_Creation\Policy_CreateUpdate.log',

    # RPC & scheduling defaults
    [bool]  $AutoChangeOnExpiration                = $true,
    [bool]  $ChangeOnlyWhenExpired                 = $true,
    [bool]  $HeartbeatEnabled                      = $true,

    # Security defaults
    [bool]  $CheckOutEnabled                       = $true,
    [bool]  $CheckOutChangePassword                = $true,
    [int]   $CheckOutIntervalMinutes               = 240,
    [int]   $ApprovalWorkflow                      = 0,
    [bool]  $RequireApprovalForAccess              = $true,
    [bool]  $RequireApprovalForEditorsAndApprovers = $true,

    # Logging & Debug
    [bool]  $Log   = $true,
    [bool]  $Debug = $false
)

# --------------------------------------------------
# Core Functions
# --------------------------------------------------

function Connect-SecretServer {
    param([string]$OauthEndpoint)
    Write-Log 'Authenticating…'
    $cred = Get-Credential
    $resp = Invoke-RestMethod -Uri $OauthEndpoint -Method Post -Body @{
        grant_type = 'password'
        username   = $cred.UserName
        password   = $cred.GetNetworkCredential().Password
    } -ContentType 'application/x-www-form-urlencoded'
    $Global:AccessToken = $resp.access_token
    Write-Log 'Authenticated' -Level Info
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('INFO','ERROR','DEBUG')][string]$Level = 'INFO'
    )
    if (-not $Log -and $Level -ne 'ERROR') { return }
    $ts = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    "$ts`t$Level`t$Message" | Out-File -FilePath $LogPath -Append
    switch ($Level) {
        'ERROR' { Write-Host $Message -ForegroundColor Red }
        'DEBUG' { if ($Debug) { Write-Host $Message -ForegroundColor DarkGray } }
        default { Write-Host $Message }
    }
}

function Resolve-ApproverGroup {
    param([string]$Name)

    # Internal user-detail search
    $payload = @{
        searchTerm = $Name; includeUsers = $true; includeAll = $false
    } | ConvertTo-Json

    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl/internals/user-detail/search?isExporting=false&paging.take=100" `
            -Method Post -Headers @{ Authorization = "Bearer $AccessToken" } `
            -ContentType 'application/json' -Body $payload
        if ($resp.records.Count -ge 1) {
            $r = $resp.records[0]
            return [PSCustomObject]@{ groupId = $r.groupId; userGroupMapType = 'User' }
        }
    } catch {}

    # Fallback to groups endpoint
    $esc = [uri]::EscapeDataString($Name)
    $grpResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/groups?filter.searchText=$esc" `
                -Headers @{ Authorization = "Bearer $AccessToken" }
    foreach ($g in $grpResp.records) {
        if ($g.name -ieq $Name -or $g.displayName -ieq $Name) {
            return [PSCustomObject]@{ groupId = $g.id; userGroupMapType = 'Group' }
        }
    }
    throw "Cannot resolve approver '$Name'"
}

function Get-ExistingPolicy {
    param(
        [string]   $BaseUrl,
        [string]   $PolicyName,
        [hashtable]$Headers,
        [bool]     $IncludeInactive = $false
    )
    $enc  = [uri]::EscapeDataString($PolicyName)
    $qs   = "filter.secretPolicyName=$enc&filter.includeInactive=$IncludeInactive"
    $uri  = "$BaseUrl/api/v1/secret-policy/search?$qs"

    Write-Log "DEBUG: GET $uri" -Level Debug
    $resp = Invoke-RestMethod -Uri $uri -Headers $Headers
    if (-not $resp.success) { throw 'Policy search failed.' }

    Write-Log "DEBUG: total=$($resp.total)" -Level Debug
    Write-Log "DEBUG: ResponseBody=`n$($resp | ConvertTo-Json -Depth 6)" -Level Debug
    return $resp
}

function Build-CreatePolicyBody {
    param(
        [string]$Name,
        [string]$Description
    )
    return @{
        data = @{
            secretPolicyName        = $Name
            secretPolicyDescription = $Description
            active                  = $true
        }
    } | ConvertTo-Json -Depth 4
}

function Build-PolicyPatchBody {
    param(
        [string] $Description,
        [array]  $Principals
    )
    return @{ 
        data = @{ 
            secretPolicyDescription = @{ dirty = $true; value = $Description }
            rpcItems = @{ 
                autoChangeOnExpiration = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [bool]$AutoChangeOnExpiration } }
                changeOnlyWhenExpired  = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [bool]$ChangeOnlyWhenExpired  } }
                heartBeatEnabled       = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [bool]$HeartbeatEnabled       } }
            }
            securityItems = @{ 
                checkOutEnabled                           = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [bool]$CheckOutEnabled } }
                checkOutChangePassword                    = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [bool]$CheckOutChangePassword } }
                checkOutIntervalMinutes                   = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [int]$CheckOutIntervalMinutes } }
                requireApprovalForAccess                  = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [bool]$RequireApprovalForAccess } }
                requireApprovalForAccessForOwnersAndApprovers = @{ dirty = $false; value = @{ policyApplyType = 'Enforced'; value = [bool]$RequireApprovalForAccess } }
                requireApprovalForAccessForEditorsAndApprovers = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [bool]$RequireApprovalForEditorsAndApprovers } }
                requireApprovalForAccessForEditors        = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = [bool]$RequireApprovalForEditorsAndApprovers } }
                approvalWorkflow                           = @{ dirty = $true; value = @{ policyApplyType = 'NotSet'; value = [int]$ApprovalWorkflow } }
                approvalGroups                             = @{ dirty = $true; value = @{ policyApplyType = 'Enforced'; value = $Principals } }
            }
        }
    } | ConvertTo-Json -Depth 8
}

function Set-FolderPolicy {
    param(
        [string] $BaseUrl,
        [string] $AccessToken,
        [string] $FolderPath,
        [int]    $PolicyId,
        [bool]   $Debug = $false
    )

    Write-Log "Looking up folder for path '$FolderPath'"
    $leaf    = ($FolderPath -split '\\')[-1]
    $escLeaf = [uri]::EscapeDataString($leaf)

    if ($Debug) { Write-Log "DEBUG: GET /api/v1/folders?filter.searchText=$escLeaf" }

    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/folders?filter.searchText=$escLeaf" `
                                  -Headers @{ Authorization = "Bearer $AccessToken" }

        if ($Debug) {
            Write-Log "DEBUG: searchText lookup returned $($resp.records.Count) candidate(s):"
            $resp.records | ForEach-Object {
                Write-Log ("    Id={0}, folderPath='{1}'" -f $_.id, $_.folderPath)
            }
        }

        $desired = $FolderPath.TrimStart('\').TrimEnd('\')
        $matches = @($resp.records | Where-Object { $_.folderPath.TrimStart('\').TrimEnd('\') -ieq $desired })

        if ($matches.Count -ne 1) {
            Write-Log "Folder path '$FolderPath' not found sor multiples were found (matched $($matches.Count))" -IsError
            return
        }

        $folderId = $matches[0].id
        Write-Log "Found exact folder → ID $folderId"
    }
    catch {
        Write-Log "Folder lookup error for '$FolderPath': $($_.Exception.Message)" -IsError
        return
    }

    try {
        $patchBody = @{
            data = @{
                secretPolicy               = @{ dirty = $true; value = $PolicyId }
                enableInheritSecretPolicy = @{ dirty = $true; value = $false }
            }
        } | ConvertTo-Json -Depth 4

        if ($Debug) { Write-Log "DEBUG: PATCH Body:`n$patchBody" }

        Invoke-RestMethod -Uri "$BaseUrl/api/v1/folder/$folderId" `
                          -Method Patch `
                          -Headers @{ Authorization = "Bearer $AccessToken" } `
                          -ContentType 'application/json' `
                          -Body $patchBody | Out-Null

        Write-Log "Assigned policy $PolicyId to '$FolderPath'"
    }
    catch {
        Write-Log "Folder-PATCH error for '$FolderPath': $($_.Exception.Message)" -IsError
    }
}

function Invoke-PolicyCreate {
    param(
        [string]   $BaseUrl,
        [hashtable]$Headers,
        [string]   $Name,
        [string]   $Description
    )
    $body = Build-CreatePolicyBody -Name $Name -Description $Description
    Write-Log "DEBUG: POST Body=`n$body" -Level Debug
    $cr = Invoke-RestMethod -Uri "$BaseUrl/api/v2/secret-policy" -Method Post -Headers $Headers -Body $body
    Write-Log "Created '$Name' → ID $($cr.secretPolicyId)" -Level Info
    return $cr.secretPolicyId
}

function Invoke-PolicyPatch {
    param(
        [string]   $BaseUrl,
        [hashtable]$Headers,
        [int]      $PolicyId,
        [string]   $Description,
        [array]    $Principals
    )
    $body = Build-PolicyPatchBody -Description $Description -Principals $Principals
    Write-Log "DEBUG: PATCH Body=`n$body" -Level Debug
    Invoke-RestMethod -Uri "$BaseUrl/api/v2/secret-policy/$PolicyId" -Method Patch -Headers $Headers -ContentType 'application/json' -Body $body | Out-Null
    Write-Log "Patched policy ID $PolicyId" -Level Info
}

# --------------------------------------------------
# Main Execution
# --------------------------------------------------

$OauthUrl = "$BaseUrl/oauth2/token"
Connect-SecretServer -OauthEndpoint $OauthUrl

$rows    = Import-Csv -Path $CsvPath
$headers = @{ Authorization = "Bearer $AccessToken"; 'Content-Type' = 'application/json' }

foreach ($row in $rows) {
    $name       = $row.PolicyName.Trim()
    $desc       = $row.PolicyDescription.Trim()
    $approvers  = $row.Approvers.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $folderPath = $row.FolderName.Trim()

    Write-Log "Processing policy '$name'"

    # Resolve approvers
    $principals = @()
    foreach ($a in $approvers) {
        try { $principals += Resolve-ApproverGroup -Name $a }
        catch { Write-Log "Could not resolve approver '$a'" -Level ERROR }
    }
    if ($principals.Count -eq 0) { Write-Log "No valid approvers; skipping." -Level ERROR; continue }

    # Search existing
    $search = Get-ExistingPolicy -BaseUrl $BaseUrl -PolicyName $name -Headers $headers
    if ($search.total -ge 1) {
        $id = ($search.records | Sort-Object secretPolicyId | Select-Object -First 1).secretPolicyId
        Write-Log "Existing policy → ID $id"
        Invoke-PolicyPatch -BaseUrl $BaseUrl -Headers $headers -PolicyId $id -Description $desc -Principals $principals
    }
    else {
        $id = Invoke-PolicyCreate -BaseUrl $BaseUrl -Headers $headers -Name $name -Description $desc
        Invoke-PolicyPatch -BaseUrl $BaseUrl -Headers $headers -PolicyId $id -Description $desc -Principals $principals
    }

    if ($folderPath) {
        Set-FolderPolicy -BaseUrl $BaseUrl -AccessToken $AccessToken -FolderPath $folderPath -PolicyId $id
    }
}

Write-Host 'Processing Complete.' -ForegroundColor Green
