<#
.SYNOPSIS
    Create or update Secret Server policies based on CSV input, then assign each policy to its folder
#>

param(
    [string]$BaseUrl   = "https://yourssurl",
    [string]$CsvPath   = "C:\temp\Policy_Creation\Policy_Info.csv",
    [string]$LogPath   = "C:\temp\Policy_Creation\Policy_CreateUpdate.log",

    # RPC & scheduling
    [bool]  $AutoChangeOnExpiration                = $true,
    [bool]  $ChangeOnlyWhenExpired                 = $true,
    [bool]  $HeartbeatEnabled                      = $true,

    # Security settings
    [bool]  $CheckOutEnabled                       = $true,
    [bool]  $CheckOutChangePassword                = $true,
    [int]   $CheckOutIntervalMinutes               = 240,
    [int]   $ApprovalWorkflow                      = 1,
    [bool]  $RequireApprovalForAccess              = $true,
    [bool]  $RequireApprovalForEditorsAndApprovers = $true,

    # Logging & Debug
    [bool]  $Log   = $true,
    [bool]  $Debug = $false
)


$OauthUrl = "$BaseUrl/oauth2/token"

function Connect-SecretServer {
    param([string]$OauthEndpoint)
    if ($Log) { Write-Host "Authenticating…" -ForegroundColor Yellow }
    $cred = Get-Credential
    $resp = Invoke-RestMethod -Uri $OauthEndpoint -Method Post -Body @{
        grant_type = "password"
        username   = $cred.UserName
        password   = $cred.GetNetworkCredential().Password
    } -ContentType 'application/x-www-form-urlencoded'
    $Global:AccessToken = $resp.access_token
    if ($Log) { Write-Host "Authenticated" -ForegroundColor Green }
}

function Write-Log {
    param([string]$Message, [switch]$IsError)
    if (-not $Log) { return }
    $ts  = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $lvl = if ($IsError) { "ERROR" } else { "INFO" }
    "$ts`t$lvl`t$Message" | Out-File -FilePath $LogPath -Append
    if ($IsError) { Write-Host $Message -ForegroundColor Red }
    else           { Write-Host $Message }
}

function Resolve-ApproverGroup {
    param([string]$Name)
    $payload = @{
        searchTerm                    = $Name
        excludeGroupIds               = @(1)
        excludeUserIds                = @()
        domainId                      = $null
        includeEveryone               = $true
        includeAll                    = $false
        includeGroups                 = $false
        includeUsers                  = $true
        onlyDoubleLockUsers           = $false
        includeInactive               = $false
        onlyIncludeApplicationAccounts= $false
    } | ConvertTo-Json

    try {
        $resp = Invoke-RestMethod -Uri "$BaseUrl/internals/user-detail/search?isExporting=false&paging.take=100" `
            -Method Post -Headers @{ Authorization="Bearer $AccessToken" } `
            -ContentType 'application/json' -Body $payload
        if ($resp.records.Count -ge 1) {
            $r = $resp.records[0]
            return [PSCustomObject]@{ Id=$r.groupId; Type="User" }
        }
    } catch { }

    $esc = [uri]::EscapeDataString($Name)
    $grpResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/groups?filter.searchText=$esc" `
        -Headers @{ Authorization="Bearer $AccessToken" }
    foreach ($g in $grpResp.records) {
        if ($g.name -ieq $Name -or $g.displayName -ieq $Name) {
            return [PSCustomObject]@{ Id=$g.id; Type="Group" }
        }
    }

    throw "Cannot resolve approver '$Name'"
}

function Set-FolderPolicy {
    param(
        [string]$BaseUrl,
        [string]$AccessToken,
        [string]$FolderPath,
        [int]$PolicyId,
        [bool]$Debug = $false
    )

    Write-Log "Looking up folder for path '$FolderPath'"

    $leaf = ($FolderPath -split '\\')[-1]
    $encLeaf = [uri]::EscapeDataString($leaf)

    if ($Debug) {
        Write-Log "DEBUG: GET /api/v1/folders?filter.searchText=$encLeaf"
    }

    try {
        $resp = Invoke-RestMethod `
            -Uri "$BaseUrl/api/v1/folders?filter.searchText=$encLeaf" `
            -Headers @{ Authorization = "Bearer $AccessToken" }

        if ($Debug) {
            Write-Log "DEBUG: searchText lookup returned $($resp.records.Count) candidate(s):"
            $resp.records | ForEach-Object {
                Write-Log ("    Id={0}, folderPath='{1}'" -f $_.id, $_.folderPath)
            }
        }

        $csvNorm = $FolderPath.Trim('\')
        $match = $resp.records | Where-Object {
            $_.folderPath.Trim('\') -ieq $csvNorm
        }

        if ($match.Count -ne 1) {
            Write-Log "Folder path '$FolderPath' not found or ambiguous (matched $($match.Count))" -IsError
            return
        }

        $folderId = $match[0].id
        Write-Log "Found exact folder → ID $folderId"
    }
    catch {
        Write-Log "Folder lookup error for '$FolderPath': $($_.Exception.Message)" -IsError
        return
    }

    try {
        $patchBody = @{
            data = @{
                secretPolicy = @{ dirty = $true; value = $PolicyId }
                enableInheritSecretPolicy = @{ dirty = $true; value = $false }
            }
        } | ConvertTo-Json -Depth 4

        if ($Debug) {
            Write-Log "DEBUG: PATCH Body JSON: $patchBody"
        }

        Invoke-RestMethod `
            -Uri "$BaseUrl/api/v1/folder/$folderId" `
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

# Main Execution
Connect-SecretServer -OauthEndpoint $OauthUrl

try {
    $rows = Import-Csv -Path $CsvPath
    Write-Log "Loaded $($rows.Count) rows from CSV"
} catch {
    Write-Log "Failed to read CSV: $($_.Exception.Message)" -IsError
    exit 1
}

foreach ($row in $rows) {
    $name       = $row.PolicyName.Trim()
    $desc       = $row.PolicyDescription.Trim()
    $approvers  = $row.Approvers.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $folderPath = $row.FolderName.Trim()

    Write-Log "Updating '$name'"

    $principals = @()
    foreach ($a in $approvers) {
        try {
            $p = Resolve-ApproverGroup -Name $a
            $principals += @{ groupId = $p.Id; userGroupMapType = $p.Type }
        } catch {
            Write-Log "Could not resolve approver '$a'" -IsError
        }
    }
    if ($principals.Count -eq 0) {
        Write-Log "No valid approvers for '$name'; skipping policy" -IsError
        continue
    }

    $escName = [uri]::EscapeDataString($name)
    $searchResp = Invoke-RestMethod -Uri "$BaseUrl/api/v1/secret-policy/search?filter.secretPolicyName=$escName" `
        -Headers @{ Authorization = "Bearer $AccessToken" }
    $found = $searchResp.records | Where-Object { $_.secretPolicyName -ieq $name }

    $isUpdate = $found.Count -eq 1
    if ($isUpdate) {
        $policyId = $found[0].secretPolicyId
        Write-Log "Found existing policy '$name' → ID $policyId"

        $current = Invoke-RestMethod -Uri "$BaseUrl/api/v2/secret-policy/$policyId" `
            -Headers @{ Authorization = "Bearer $AccessToken" }
        $descSame = $current.secretPolicyDescription -eq $desc
        $currApps = @($current.securityItems.approvalGroups.value)

        $diff = Compare-Object `
            ($currApps | Sort-Object groupId, userGroupMapType) `
            ($principals | Sort-Object groupId, userGroupMapType)

        if ($descSame -and $diff.Count -eq 0) {
            Write-Log "No changes for '$name'; skipping PATCH"
        } else {
            $body = @{
                data = @{
                    secretPolicyDescription = $desc
                    securityItems = @{
                        approvalGroups = @{
                            dirty = $true
                            value = @{
                                policyApplyType = "Enforced"
                                value           = $principals
                            }
                        }
                    }
                }
            } | ConvertTo-Json -Depth 6

            Invoke-RestMethod -Uri "$BaseUrl/api/v2/secret-policy/$policyId" `
                -Method Patch `
                -Headers @{ Authorization = "Bearer $AccessToken" } `
                -ContentType 'application/json' `
                -Body $body | Out-Null

            Write-Log "Patched '$name'"
        }
    } else {
        $createBody = @{
            data = @{
                secretPolicyName        = $name
                secretPolicyDescription = $desc
                active                  = $true
            }
        } | ConvertTo-Json -Depth 4

        $cr = Invoke-RestMethod -Uri "$BaseUrl/api/v2/secret-policy" `
            -Method Post `
            -Headers @{ Authorization = "Bearer $AccessToken" } `
            -ContentType 'application/json' `
            -Body $createBody

        $policyId = $cr.secretPolicyId
        Write-Log "Created '$name' → ID $policyId"

        $patchBody = @{
            data = @{
                securityItems = @{
                    approvalGroups = @{
                        dirty = $true
                        value = @{
                            policyApplyType = "Enforced"
                            value           = $principals
                        }
                    }
                }
            }
        } | ConvertTo-Json -Depth 6

        Invoke-RestMethod -Uri "$BaseUrl/api/v2/secret-policy/$policyId" `
            -Method Patch `
            -Headers @{ Authorization = "Bearer $AccessToken" } `
            -ContentType 'application/json' `
            -Body $patchBody | Out-Null

        Write-Log "Patched '$name' after create"
    }

    if ($folderPath) {
        Set-FolderPolicy -BaseUrl $BaseUrl -AccessToken $AccessToken -FolderPath $folderPath -PolicyId $policyId -Debug:$Debug
    }
}

Write-Host "Processing Complete." -ForegroundColor Green
