<#
    .SYNOPSIS
    Script used to sync password value between a parent and child secret

    .DESCRIPTION
    Child secret is defined in the custom field of the Secret and listed as a comma-separated list (**no spaces**)

    .NOTES
    - Secret IDs specified in the Sync field should have no spaces and comma-separated
    - Arguments used in the Script Task arguments field need to be wrapped in double-quotes
    - Event Pipelines: Allow Confidential Secret Fields to be used in Scripts setting must be enabled (under ConfigurationAdvanced.aspx)

    Expected arguments:
    "$[ADD:1]$URL" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "<Slug name>" "${FIELD}" "$SYNC"

    .EXAMPLE
    "$[ADD:1]$URL" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "private-key" "$PRIVATEKEY" "$SYNC"

    Updates the private key value on the child secrets specified in the Sync field of the parent secret.
#>

$SecretServer = $args[0]
$SSCred = [pscredential]::new($args[1], (ConvertTo-SecureString -String $args[2] -AsPlainText -Force))
$secretId = $args[3]
$slugName = $args[4]
$slugValue = $args[5]
$syncItems = $args[6]
$isPrivate = $args[7]

$childSecrets = $syncItems.Split(',')

$logFileName = "sync_secret_$(Get-Date -Format 'yyyy_MM_ddThh_mm_ss_fff').txt"
$logFile = "C:\thycotic\$logFileName"

try {
    New-Item $logFile -ItemType File -Force
} catch {
    throw "Issue creating log file $_"
}

# Parameter logging:
Add-Content -Path $logFile -Value "SecretServer: $SecretServer"
Add-Content -Path $logFile -Value "Secret ID (parent): $secretID"
Add-Content -Path $logFile -Value "Child Secrets: $childSecrets"

$checkoutComment = "Sync process for Secret $secretId to sync password"

Add-Content -Path $logFile -Value 'Importing Thycotic.SecretServer module'
if (Get-Module Thycotic.SecretServer -ListAvailable ) {
    Import-Module Thycotic.SecretServer
} else {
    Add-Content -Path $logFile -Value "Thycotic.SecretServer module not found on $env:COMPUTERNAME - attempting install"
    try {
        Install-Module Thycotic.SecretServer -MinimumVersion 0.39.0 -Scope AllUsers -Force
    } catch {
        Add-Content -Path $logFile -Value "Could not auto install Thycotic.SecretServer module on $env:COMPUTERNAME - please resolve. More details: https://thycotic-ps.github.io/thycotic.secretserver/docs/install/"
        throw "Could not auto install Thycotic.SecretServer module on $env:COMPUTERNAME - please resolve. More details: https://thycotic-ps.github.io/thycotic.secretserver/docs/install/"
    }
    Import-Module Thycotic.SecretServer
}

try {
    Add-Content -Path $logFile -Value "Creating session to $SecretServer"
    $session = New-TssSession -SecretServer $SecretServer -Credential $SSCred
} catch {
    Add-Content -Path $logFile -Value "[New-TssSession] Issue creating session: $($_.Exception)"
    throw "Issue authenticating: $_"
}

foreach ($secret in $childSecrets) {
    $msgPrefix = "[$(Get-Date -Format 'yyyy_MM_ddThh_mm_ss_fff')] | [$secret] |"
    $currentState = Get-TssSecretState -TssSession $session -Id $secret
    Add-Content -Path $logFile -Value "$msgPrefix Working on Child Secret: [$($currentState.SecretName)]"

    Add-Content -Path $logFile -Value "$msgPrefix Current state: [$($currentState.SecretState)]"
    $process = $false
    switch ($currentState.SecretState) {
        'RequiresCheckoutAndComment' {
            Add-Content -Path $logFile -Value "$msgPrefix Comment will be provided to checkout. State: $_"
            $process = $true
        }
        'RequiresComment' {
            Add-Content -Path $logFile -Value "$msgPrefix Comment will be provided to checkout. State: $_"
            $process = $true
        }
        'None' {
            $process = $true
        }
    }

    if ($process) {
        if ($slugValue -match '--BEGIN.+KEY') {
            Add-Content -Path $logFile -Value "$msgPrefix Field value detected to be an SSH key, updating [$slugName]"
            if ($isPrivate -eq 1) {
                Add-Content -Path $logFile -Value "$msgPrefix File name to be used [Private Key.key]"
                $filename = 'Private Key.key'
            } else {
                Add-Content -Path $logFile -Value "$msgPrefix File name to be used [Public Key.key]"
                $filename = 'Public Key.key'
            }
            try {
                Set-TssSecretField -TssSession $session -Id $secret -Slug $slugName -Value $slugValue -Filename $filename -Comment $checkoutComment -ForceCheckIn -ErrorAction Stop
            } catch {
                Add-Content -Path $logFile -Value "$msgPrefix Issue updating field $($slugName): $($_.Exception)"
            }
        } else {
            Add-Content -Path $logFile -Value "$msgPrefix Field value detected, updating field [$slugName]"
            try {
                Set-TssSecretField -TssSession $session -Id $secret -Slug $slugName -Value $slugValue -Comment $checkoutComment -ForceCheckIn -ErrorAction Stop
            } catch {
                Add-Content -Path $logFile -Value "$msgPrefix Issue updating field $($slugName): $($_.Exception)"
            }
        }

    } else {
        Add-Content -Path $logFile -Value "$msgPrefix Cannot process: $($currentState.SecretState)"
    }

    if ((Get-TssSecretState -TssSession $session -Id $secret).IsCheckedOut) {
        Set-TssSecret -TssSession $session -Id $secret -CheckIn
        Add-Content -Path $logFile -Value "$msgPrefix Checking secret in"
    }

    Add-Content -Path $logFile -Value "$msgPrefix ----------- [$($currentState.SecretName)]"
}
$session.SessionExpire()
Add-Content -Path $logFile -Value "$msgPrefix ----------- Session Closed -----------"
