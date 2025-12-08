<#
.SYNOPSIS
    Delinea RPC: Change ESXi Local Account Password via vCenter (ESXCLI) - v3

.DESCRIPTION
    Remote Password Change (RPC) script that:
        • Connects to vCenter using a privileged service account
        • Confirms the ESXi host exists in vCenter
        • Uses ESXCLI via vCenter (Get-EsxCli -VMHost -V2)
        • Validates the local ESXi account exists
        • Updates the local ESXi account password
        • Logs all actions to both console + log file

ARGUMENTS: $HOST $USERNAME $NEWPASSWORD $VCENTER $[1]DOMAIN $[1]USERNAME $[1]PASSWORD

    1. MACHINE        - ESXi Hostname or IP (FQDN preferred)
    2. USERNAME       - ESXi Local Account Username (e.g. root)
    3. NEWPASSWORD    - New Password for ESXi Local Account
    4. VCENTER        - vCenter Server Hostname or IP
    5. PRIV_DOMAIN    - Domain for the service account
    6. PRIV_USERNAME  - Service account username
    7. PRIV_PASSWORD  - Service account password

NOTES:
    • All operations go through vCenter using ESXCLI.
    • vCenter account must have permissions to manage local accounts
      on the target ESXi host
#>

# =====================================================================
# ARGUMENTS
# =====================================================================

$Machine        = $args[0]
$Username       = $args[1]
$NewPassword    = $args[2]
$VCENTER        = $args[3]
$PRIV_DOMAIN    = $args[4]
$PRIV_USERNAME  = $args[5]
$PRIV_PASSWORD  = $args[6]
$LOG_ENABLED    = 'true'
$LOG_PATH       = "C:\Logs\vcenter_${Machine}_rpc_esxcli_v3.log"

# Normalize logging flag
$LOG_ENABLED = [string]$LOG_ENABLED
$LOG_ENABLED = $LOG_ENABLED.Trim().ToLower()

if ($LOG_ENABLED -eq "true") {

    if (-not $LOG_PATH) {
        throw "LOG_ENABLED is TRUE but LOG_PATH is missing."
    }

    $LOG_PATH = $LOG_PATH.Trim()

    $logDir = Split-Path $LOG_PATH -Parent
    if (-not (Test-Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $LOG_PATH)) {
        New-Item -Path $LOG_PATH -ItemType File -Force | Out-Null
    }
}

# =====================================================================
# LOGGING FUNCTION
# =====================================================================

function Log {
    param([string]$msg)

    if ($LOG_ENABLED -ne "true") { return }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp [RPC] $msg"

    Write-Output $line
    Add-Content -Path $LOG_PATH -Value $line
}

# =====================================================================
# GLOBAL SETTINGS / PRE-CHECKS
# =====================================================================

$ErrorActionPreference = 'Stop'

[Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

Log "=== RPC START ==="
Log "Target host: $Machine | Account: $Username | vCenter: $VCENTER"

# =====================================================================
# BUILD CREDENTIAL
# =====================================================================

if ($PRIV_DOMAIN) {
    $loginUser = "$PRIV_DOMAIN\$PRIV_USERNAME"
} else {
    $loginUser = $PRIV_USERNAME
}

$securePass = ConvertTo-SecureString $PRIV_PASSWORD -AsPlainText -Force
$svcCred    = New-Object System.Management.Automation.PSCredential($loginUser, $securePass)

Log "Using vCenter credential: $loginUser"

# =====================================================================
# VCENTER CONNECTION
# =====================================================================

$vcConn = $null

try {
    # --------------------------------------------------------------
    # CONNECT TO VCENTER
    # --------------------------------------------------------------
    try {
        Log "Connecting to vCenter: $VCENTER ..."
        $vcConn = Connect-VIServer -Server $VCENTER -Credential $svcCred -Force -ErrorAction Stop
        Log "Connected to vCenter."
    }
    catch {
        Log "Failed to connect to vCenter."
        Log "[ERROR] vCenter connection exception: $($_.Exception.Message)"
        $fullErr = ($_ | Out-String)
        Log "[ERROR] Full vCenter error:`n$fullErr"
        throw "vCenter login failed ($VCENTER): $($_.Exception.Message)"
    }

    # --------------------------------------------------------------
    # LOCATE HOST IN VCENTER
    # --------------------------------------------------------------
    try {
        Log "Locating ESXi host '$Machine' in vCenter..."
        $vmhost = Get-VMHost -Name $Machine -Server $vcConn -ErrorAction Stop
        Log "Found ESXi host '$Machine' in vCenter."
    }
    catch {
        Log "Host not found in vCenter."
        Log "[ERROR] Host lookup exception: $($_.Exception.Message)"
        $fullErr = ($_ | Out-String)
        Log "[ERROR] Full host error:`n$fullErr"
        throw "Host '$Machine' not found in vCenter: $($_.Exception.Message)"
    }

    # --------------------------------------------------------------
    # GET ESXCLI CONTEXT VIA VCENTER
    # --------------------------------------------------------------
    $esxcli = $null

    try {
        Log "Initializing ESXCLI context for host '$Machine' (via vCenter)..."
        $esxcli = Get-EsxCli -VMHost $vmhost -V2 -Server $vcConn -ErrorAction Stop
        Log "ESXCLI context acquired for host '$Machine'."
    }
    catch {
        Log "Failed to initialize ESXCLI for host '$Machine'."
        Log "[ERROR] ESXCLI init exception: $($_.Exception.Message)"
        $fullErr = ($_ | Out-String)
        Log "[ERROR] Full ESXCLI init error:`n$fullErr"
        throw "Failed to initialize ESXCLI for host '$Machine': $($_.Exception.Message)"
    }

    # --------------------------------------------------------------
    # VALIDATE ACCOUNT EXISTS
    # --------------------------------------------------------------
    try {
        Log "Validating existence of local ESXi account '$Username' on host '$Machine'..."

        # system.account.list returns all local users
        $accountList = $esxcli.system.account.list.Invoke()

        $targetAccount = $accountList | Where-Object { $_.id -eq $Username }

        if (-not $targetAccount) {
            Log "ESXi account '$Username' not found on host '$Machine'."
            throw "Local account '$Username' does not exist on host '$Machine'."
        }

        Log "ESXi account '$Username' found on host '$Machine'."
    }
    catch {
        Log "Account validation failed."
        Log "[ERROR] Exception during account list: $($_.Exception.Message)"
        $fullErr = ($_ | Out-String)
        Log "[ERROR] Full account list error:`n$fullErr"
        throw "Failed to validate account '$Username' on host '$Machine': $($_.Exception.Message)"
    }

    # --------------------------------------------------------------
    # CHANGE PASSWORD USING ESXCLI
    # --------------------------------------------------------------
    try {
        Log "Updating password for '$Username' on host '$Machine' via ESXCLI..."

        # Build args for system.account.set
        $setArgs = $esxcli.system.account.set.CreateArgs()
        $setArgs.id                   = $Username
        $setArgs.password             = $NewPassword
        $setArgs.passwordconfirmation = $NewPassword

        if ($targetAccount -and $targetAccount.description) {
            $setArgs.description = $targetAccount.description
        }

        $result = $esxcli.system.account.set.Invoke($setArgs)
        Log "ESXCLI returned: $result"

        if ($result -ne $true) {
            Log "ESXCLI did not return 'True' for password update on '$Username' (host '$Machine')."
            throw "Password update did not complete successfully. ESXCLI result: $result"
        }

        Log "Password update SUCCESSFUL for account '$Username' on host '$Machine'."
    }
    catch {
        Log "Password change failed."
        Log "[ERROR] Exception during ESXCLI password change: $($_.Exception.Message)"

        if ($_.CategoryInfo) {
            Log "[ERROR] Category : $($_.CategoryInfo.Category)"
            Log "[ERROR] Target   : $($_.CategoryInfo.TargetName)"
        }

        $fullErr = ($_ | Out-String)
        Log "[ERROR] Full ESXCLI error record:`n$fullErr"

        throw "Password update failed on host '$Machine' (ESXCLI): $($_.Exception.Message)"
    }
}
finally {
    if ($vcConn) {
        try {
            Log "Disconnecting from vCenter..."
            Disconnect-VIServer -Server $vcConn -Confirm:$false -ErrorAction SilentlyContinue
            Log "Disconnected from vCenter."
        }
        catch {
            Log "[WARN] Failed to disconnect vCenter session cleanly: $($_.Exception.Message)"
        }
    }

    Log "=== RPC END ==="
}

exit 0
