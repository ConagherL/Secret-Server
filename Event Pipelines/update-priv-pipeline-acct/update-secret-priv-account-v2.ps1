<#
    .SYNOPSIS
    Script used to update the RPC privileged secret on a given Secret

    .DESCRIPTION
    Script used to update the RPC privileged secret on a given Secret

    .NOTES
    - Arguments used in the Script Task arguments field need to be wrapped in double-quotes
    - Event Pipelines: Allow Confidential Secret Fields to be used in Scripts setting must be enabled (under ConfigurationAdvanced.aspx)

    Expected arguments:
    "$[ADD:1]$URL" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "$MACHINE <or $HOST>" "<Priv Folder ID>" "<priv username>"

    .EXAMPLE
    "$[ADD:1]$URL" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "$MACHINE" "28" "capam"

    Updates the privileged secret on SecretId to the privileged secret found as $MACHINE\capam
#>

$SecretServer = $args[0]
$SSCred = [pscredential]::new($args[1], (ConvertTo-SecureString -String $args[2] -AsPlainText -Force))
$secretId = $args[3]
$secretHostname = $args[4]
$privFolderId = $args[5]
$privUsername = $args[6]

$logFileName = "update_priv_secret_log_$(Get-Date -Format 'yyyy_MM_ddThh_mm_ss_fff').txt"
$logFile = "C:\thycotic\$logFileName"

#region setup
if (Get-Module Thycotic.SecretServer -ListAvailable ) {
    Import-Module Thycotic.SecretServer
} else {
    try {
        Install-Module Thycotic.SecretServer -MinimumVersion 0.52.0 -Scope AllUsers -Force
    } catch {
        throw "Could not auto install Thycotic.SecretServer module on $env:COMPUTERNAME - please resolve. More details: https://thycotic-ps.github.io/thycotic.secretserver/docs/install/"
    }
    Import-Module Thycotic.SecretServer
}

try {
    Start-TssLog $logFile -ScriptVersion "v2" -ErrorAction SilentlyContinue
} catch {
    throw "Issue creating log file $_"
}

# Parameter logging:
Write-TssLog -LogFilePath $logFile -Message "SecretServer: $SecretServer"
Write-TssLog -LogFilePath $logFile -Message "Secret ID (parent): $secretID"
Write-TssLog -LogFilePath $logFile -Message "Child Secrets: $childSecrets"

try {
    $session = New-TssSession -SecretServer $SecretServer -Credential $SSCred -ErrorAction Stop
} catch {
    Write-TssLog -LogFilePath $logFile -MessageType ERROR -Message "[New-TssSession] Issue creating session: $($_.Exception)"
    throw "Issue authenticating: $_"
}
#endregion setup

$privSecretName = $secretHostname, $privUserName -join '\'
try {
    $privSearchParams = @{
        TssSession = $session
        FolderId = $privFolderId
        SearchText = $privSecretName
    }
    $privSecret = Search-TssSecret @privSearchParams -ErrorAction Stop
} catch {
    Write-TssLog -LogFilePath $logFile -MessageType ERROR -Message "Unable to find privileged secret matching [$privSecretName]"
    throw "Unable to find privileged secret matching [$privSecretName]"
}

try {
    $setPrivParams = @{
        TssSession = $session
        Id = $secretId
        PrivilegedSecretId = $privSecret.SecretId
    }
    Set-TssSecretRpcPrivileged @setPrivParmas -ErrorAction Stop
} catch {
    Write-TssLog -LogFilePath $logFile -MessageType ERROR -Message "[Set-TssSecretRpcPrivileged] issue setting privileged secret to [$($privSecret.SecretName)] on secret [$secretId]"
    throw "[Set-TssSecretRpcPrivileged] issue setting privileged secret to [$($privSecret.SecretName)] on secret [$secretId]"
}
# close out session and log file
$session.SessionExpire()
Stop-TssLog -LogFilePath $logFile