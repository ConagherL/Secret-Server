<#
    Delinea Platform - Engine Pool API Query Script
    
    PREREQUISITES:
      1. Service User created in Platform (Access > Service Users) with Client ID & Secret
      2. Service User assigned to a Group with a Role that has engine management read permissions
      3. Your Tenant Secondary ID (X-MT-SecondaryId) - see Step 0 below
#>

# ============================================================
#  STEP 0: SET YOUR VARIABLES
# ============================================================
# Your tenant hostname (just the name, not the full URL)
$TenantHostname    = "YOURTENANT"

# Service user credentials from Platform > Access > Service Users
$ClientId          = "your.serviceuser"
$ClientSecret      = "YourClientSecretHere"

# Tenant Secondary ID - To find this:
#   1. Go to Engine Management in the Platform API docs : https://docs.delinea.com/online-help/platform-api/engine-management.htm
#   2. Populate the Platform name and provide password to authenticate
#   3. Expand any endpoint (e.g. /api/Engines/{id}) and find the Tenant Secondary ID value
#   4. Copy that GUID and paste it here
$TenantSecondaryId = "00000000-0000-0000-0000-000000000000"


# ============================================================
#  STEP 1: AUTHENTICATE
# ============================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$tokenUrl = "https://$TenantHostname.delinea.app/identity/api/oauth2/token/xpmplatform"

$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method POST `
    -ContentType "application/x-www-form-urlencoded" `
    -Body @{
        grant_type    = "client_credentials"
        scope         = "xpmheadless"
        client_id     = $ClientId
        client_secret = $ClientSecret
    }

$token = $tokenResponse.access_token
Write-Host "Authenticated - token expires in $($tokenResponse.expires_in) seconds"


# ============================================================
#  STEP 2: SET COMMON HEADERS
# ============================================================
# Every Engine Pool API call needs these three headers
$headers = @{
    "Authorization"    = "Bearer $token"
    "Content-Type"     = "application/json"
    "X-Api-Version"    = "1.0"
    "X-MT-SecondaryId" = $TenantSecondaryId
}

# Base URL - note the /engine-pool path is required
$baseUrl = "https://$TenantHostname.delinea.app/engine-pool"


# ============================================================
#  STEP 3: LIST ALL SITES
#  POST /api/Sites/search
# ============================================================
$sitesBody = @{ page = @{ skip = 0; take = 100; getTotalCount = $true } } | ConvertTo-Json

$sites = Invoke-RestMethod -Uri "$baseUrl/api/Sites/search" `
    -Method POST -Headers $headers -Body $sitesBody

Write-Host "`nSites found: $($sites.totalRecords)"
$sites.sites | Format-Table name, id, isDefault -AutoSize


# ============================================================
#  STEP 4: LIST ALL ENGINES
#  POST /api/Engines/search
# ============================================================
$enginesBody = @{
    includeGroups = $true
    page = @{ skip = 0; take = 100; getTotalCount = $true }
} | ConvertTo-Json

$engines = Invoke-RestMethod -Uri "$baseUrl/api/Engines/search" `
    -Method POST -Headers $headers -Body $enginesBody

# State mapping: 0=Unknown, 1=Online, 2=Offline, 3=Degraded,
#                4=Installing, 5=Upgrading, 6=Deleted, 7=Uninstalling
$stateMap = @{ 0="Unknown"; 1="Online"; 2="Offline"; 3="Degraded"; 4="Installing"; 5="Upgrading"; 6="Deleted"; 7="Uninstalling" }

Write-Host "`nEngines found: $($engines.totalRecords)"
foreach ($e in $engines.engines) {
    Write-Host "`n  $($e.name) ($($e.machineName))" -ForegroundColor White
    Write-Host "    State:  $($stateMap[[int]$e.state])"
    Write-Host "    Site:   $($e.siteId)"
    Write-Host "    OS:     $($e.operatingSystem) $($e.osVersion)"
}


# ============================================================
#  STEP 5: GET HEARTBEATS FOR A SPECIFIC ENGINE
#  GET /api/Engines/{id}/Heartbeats
# ============================================================
foreach ($e in $engines.engines) {
    $hb = Invoke-RestMethod -Uri "$baseUrl/api/Engines/$($e.id)/Heartbeats" `
        -Method GET -Headers $headers

    if ($hb.items) {
        $latest = ($hb.items | Sort-Object createdOn -Descending | Select-Object -First 1).createdOn
        Write-Host "  $($e.name) - Last heartbeat: $latest"
    }
}


# ============================================================
#  STEP 6: GET WORKLOAD DEPLOYMENTS PER ENGINE
#  GET /api/Engines/{id}/Deployments
# ============================================================
foreach ($e in $engines.engines) {
    $dep = Invoke-RestMethod -Uri "$baseUrl/api/Engines/$($e.id)/Deployments" `
        -Method GET -Headers $headers

    if ($dep.items) {
        Write-Host "`n  $($e.name) workloads:"
        foreach ($d in $dep.items) {
            Write-Host "    - $($d.workload.displayName): state=$($stateMap[[int]$d.state])"
        }
    }
}


# ============================================================
#  STEP 7: LIST AVAILABLE WORKLOADS FOR WINDOWS
#  GET /api/Workloads/available/{os}
# ============================================================
$workloads = Invoke-RestMethod -Uri "$baseUrl/api/Workloads/available/Windows" `
    -Method GET -Headers $headers

Write-Host "`nAvailable Windows workloads: $($workloads.totalRecords)"
$workloads.workloads | Format-Table displayName, name, description -AutoSize