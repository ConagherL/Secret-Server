# Introduction

When the need arises to have a duplicate account managed across multiple Secrets, an Event Pipeline can keep the desired field in sync between them. The Event Pipeline script used in this process is written to allow you to control the exact field synchronized between the parent and child.

## Secret Server Minimum Version

This Event Pipeline and script were written and tested on `10.9.000064`.

# Limitations

Secret Server advanced features allow you to put workflows and various restrictions on how Secrets can be accessed. The following list provides the secret configurations that are explicitly not supported in this processing:

- Child secret configured to require Approval
- Child secret configured to rotate password on Check-In

# Dependencies

The following items must be in place on your Secret Server for the Event Pipeline to be implemented appropriately.

## Sync Field

A **Sync** field must be added to the parent's Secret Template with the **Type** set to **Notes**. You can configure this field to allow only the Owner to provide the child secrets that are synchronized.

If reluctant to adding a custom field to the template, you can use the **Notes** field. 

## Child Secret IDs

Collect the Secret IDs for the child's secrets that will be synchronized. These will be placed in the Sync field of the parent secret.

## Secret Server Local User

A Secret Server Local User needs to be created as an Application Account to authenticate to Secret Server for the script. This account is utilized by the script used by the Event Pipeline. This account will need to be added as a secret in Secret Server to provide it to the Event Pipeline script securely.

> A Remote Password Change can be created for Secret Server Local User accounts if desired.

# Permission

API account utilized will require the following permissions:

| Parent Secret(s) | Child Secret(s) |
| ---------------- | --------------- |
| View | Edit |

# Secret Template

Add a field called **Sync** to the template utilized by the parent secret. Ensure the type is set to **Notes**.

# Script

1. Navigate to **Admin | Scripts**
1. Click the **Create new** under PowerShell tab
1. Enter Name: **Sync Secret**
1. Enter Description as desired
1. Select **Untyped** category
1. Paste contents of the Script at the end of this document.

## Logging

The script is written to log to a physical file that will be created either on the web nodes or Distributed Engine(s). You can adjust the `$logFile` variable in the script to adjust the full path. The filename is auto-generated with a timestamp, so each Event Pipeline run will generate a separate file for troubleshooting.

> **No sensitive** data is written to the log file.

# Creating Event Pipeline Policy

1. Navigate to **Admin | See All | Event Pipeline Policy**
1. Click the button **Add Policy**
1. Click the radio button **Create New Policy**
1. Enter **Policy Name**: _Secret Sync - Parent to Child_
1. Provide Policy Description, if desired
1. Click the drop-down **Policy Type** select **Secret**
1. Click the button **Create**

## Creating the Event Pipelines

A pipeline should be created for each field you want to synchronize from the parent secret. The arguments used in the Script Task will determine what field and field values are synchronized.

1. Click the button **Add Pipeline**
1. Click the radio button **Create New Pipeline**
1. Triggers, add **Secret: Create** and **Secret: Edit**
1. Filters, add **Secret has Field**, select **Sync** for the **Secret Field Name**
1. Click the button **Save**
1. **Add additional filter** for the desired field the pipeline will synchronize.
1. Tasks, add **Script Task**
1. **Script** select **Sync Secrets**
1. Check box for **Use Site Run As Secret**
1. Script Args, use one of the following:

    - For basic password or passphrase fields: `"$[ADD:1]$URL" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "{slug name}" "${fieldname}" "$SYNC"`
        - Replace `{slug name}` and `{fieldname}` with the appropriate value
        - You can hardcode the URL. Example: `"https://URL/SecretServer" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "password" "$PASSWORD" "$SYNC"`
        - If using the Notes field for the sync secrets: `"https://URL/SecretServer" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "password" "$PASSWORD" "$NOTES"`
    - For SSH Key files: `"$[ADD:1]$URL" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "{slug name}" "{fieldname}" "$SYNC" 1`
        - Replace `{slug name}` and `{fieldname}` with the appropriate value
        - The last value on the arguments should be set to 0 (public key) or 1 (private key)

1. Select desired **Run Site**
1. Click **No Secret Selected** for **Additional Secret 1** and add the Secret to be used for API authentication.
1. Click **Save**
1. (4) Name, provide **Pipeline Name**, e.g., _Sync {field name} Field_

## Active Pipeline and Policy

When completed with adding the pipelines desired, ensure the Pipeline and Policy are Active.

## Targets

The folders that store the parent secrets can be selected when you configure the Event Pipeline Policy, or configured via Secret Policy using the _Security Settings_ policy item _Event Pipeline Policy_.

# Parent Secret(s)

When you are adding the list of Secret IDs for the child secrets ensure you enter then as comma-separated **with no spaces**.

This is **a correct** value: `453,321,9087,8095`

This is **an incorrect** value: `453, 321, 9087, 8095`

# Script

```powershell
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
    "https://URL/SecretServer" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "password" "$PASSWORD" "$SYNC"
    "https://URL/SecretServer" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "password" "$PASSWORD" "$NOTES"

    Updates the private key (or password) value on the child secrets specified in the Sync field of the parent secret.
#>

$SecretServer = $args[0]
$SSCred = [pscredential]::new($args[1],(ConvertTo-SecureString -String $args[2] -AsPlainText -Force))
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

Add-Content -Path $logFile -Value "Importing Thycotic.SecretServer module"
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
        if ($slugValue -match "--BEGIN.+KEY") {
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
```
