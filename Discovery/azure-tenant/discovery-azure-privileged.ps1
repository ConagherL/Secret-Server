<#
    Update the variables accordingly:

    AzureAdRoles - Privileged Roles to scan for Accounts
    AzureSubRoles - Subscription-level roles to scan for members
    LogDirectory - Folder on Distributed Engine/Web Nodes to write the log file for this process
#>
$AzureAdRoles = 'Global administrator', 'Privileged role administrator'
$AzureSubRoles = 'Owner', 'Contributor'
$LogDirectory = 'C:\thycotic'

<# +++++++++++++++ No changes below this line +++++++++++++++ #>
$privDomain = $args[0]
$privUsername = $args[1]
$privPassword = ConvertTo-SecureString -String $args[2] -AsPlainText -Force
$tenantId = $args[3].Trim('OU=')

$privUsername = "$privUsername@$privDomain"
$tenantCred = [pscredential]::new($privUsername,$privPassword)

$fileName = "azure_ad_discovery_$(Get-Date -Format FileDateTime).log"
$logFile = [IO.Path]::Combine($LogDirectory,$fileName)
<# Log cleanup #>
$logFilesFound = Get-ChildItem $LogDirectory -Filter 'azure_ad_discovery*.log'
if ($logFilesFound.Count -gt 5) {
    $toDelete = $logFilesFound | Where-Object {$_.Name -notin ($logFilesFound | Sort-Object LastWriteTime -Descending | Select-Object Name -First 10).Name}
    $toDelete | Remove-Item -Force -ErrorAction SilentlyContinue
}

# Generate log file for troubleshooting
if (-not (Test-Path $logFile)) {
    New-Item $logFile -ItemType File -Force
} else {
    Remove-Item $logFile -Force -ErrorAction SilentlyContinue
    New-Item $logFile -ItemType File -Force
}

Add-Content -Path $logFile -Value "Tenant: $tenantId"
try {
    Connect-AzureAD -TenantId $tenantId -Credential $tenantCred
    Add-Content -Path $logFile -Value "Connected successfully to Azure AD Tenant [$tenantId]" -ErrorAction SilentlyContinue
} catch {
    Add-Content -Path $logFile -Value "Issue connecting to Azure AD Tenant [$tenantId]: $($_)" -ErrorAction SilentlyContinue
    throw "Issue connecting to Tenant [$tenantId]: $($_)"
}

try {
    Connect-AzAccount -TenantId $tenantId -Credential $tenantCred
    Add-Content -Path $logFile -Value "Connected successfully to Azure Subscription [$tenantId]" -ErrorAction SilentlyContinue
} catch {
    Add-Content -Path $logFile -Value "Issue connecting to Azure Subscription [$tenantId]: $($_)" -ErrorAction SilentlyContinue
    throw "Issue connecting to Azure Subscription [$tenantId]: $($_)"
}

$discoveredAzureAdAccounts = @()
foreach ($role in $AzureAdRoles) {
    try {
        $roleObject = Get-AzureAdDirectoryRole | Where-Object DisplayName -EQ $role
        Add-Content -Path $logFile -Value "Successfully retrieved Azure AD Role [$role]" -ErrorAction SilentlyContinue
    } catch {
        Add-Content -Path $logFile -Value "Issue getting Azure AD Role [$role] on Tenant [$tenantId]" -ErrorAction SilentlyContinue
        throw "Issue getting Azure AD Role [$role] on Tenant [$tenantId]"
    }
    try {
        $members = $roleObject | Get-AzureADDirectoryRoleMember | Where-Object { $_.UserType -eq 'Member' -and $_.UserPrincipalName -notlike "*#EXT#*" } | Select-Object UserPrincipalName, UserType, DisplayName, @{L = 'MemberOf';E = { $role } }
        Add-Content -Path $logFile -Value "Successfully retrieved Azure AD Role [$role] members on Tenant [$tenantId]" -ErrorAction SilentlyContinue
    } catch {
        Add-Content -Path $logFile -Value "Issue retrieved Azure AD Role [$role] members on Tenant [$tenantId]: $($_)" -ErrorAction SilentlyContinue
        throw "Issue retreiving members of role [$role] on Tenant [$tenantId]"
    }
    $discoveredAzureAdAccounts += $members
}

$discoveredSubAccounts = @()
foreach ($role in $AzureSubRoles) {
    try {
        $discoveredSubAccounts = Get-AzRoleAssignment -RoleDefinitionName $role -IncludeClassicAdministrators | Where-Object { $_.SignInName -notlike "*#EXT#*" -and -not [string]::IsNullOrEmpty($_.SignInName) } | Select-Object ObjectId, ObjectType, DisplayName, SignInName, @{L = 'MemberOf';E = { $_.RoleDefinitionName } }
        Add-Content -Path $logFile -Value "Successfully retrieved [$role] assignments on Tenant [$tenantId]" -ErrorAction SilentlyContinue
    } catch {
        Add-Content -Path $logFile -Value "Issue retrieved [$role] assignments on Tenant [$tenantId]: $($_)" -ErrorAction SilentlyContinue
        throw "Issue retreiving [$role] assignments on Tenant [$tenantId]"
    }
}
# prep output
$results = @()
foreach ($account in $discoveredAzureAdAccounts) {
    $tenantDomain = ($account.UserPrincipalName -split '@')[-1]
    $tenantUsername = ($account.UserPrincipalName -split '@')[0]
    $results += [pscustomobject]@{
        Domain   = $tenantDomain
        Username = $tenantUsername
        Type     = $account.UserType
        MemberOf = $account.MemberOf
    }
    Add-Content -Path $logFile -Value "Azure AD Account Name found:`n $($account.DisplayName) - $($account.UserPrincipalName)" -ErrorAction SilentlyContinue
}
foreach ($account in $discoveredSubAccounts) {
    $tenantDomain = ($account.SignInName -split '@')[-1]
    $tenantUsername = ($account.SignInName -split '@')[0]
    $results += [pscustomobject]@{
        Domain   = $tenantDomain
        Username = $tenantUsername
        Type     = $account.ObjectType
        MemberOf = $account.MemberOf
    }
    Add-Content -Path $logFile -Value "Azure Subscription Account Name found:`n $($account.DisplayName) - $($account.SignInName)" -ErrorAction SilentlyContinue
}

Add-Content -Path $logFile -Value "Total privileged accounts identified on Tenant [$tenantId]: $($results.Count)" -ErrorAction SilentlyContinue
return $results