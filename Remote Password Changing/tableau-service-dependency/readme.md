# Introduction

This document provides the details for having Secret Server update the password for Tableau service account.

> **NOTE** TSM utility used for this changer does not report success or failure

# Permissions

The utility for updating the service resides on the Tableau server(s). A privileged account for doing a PS remoting session is required, unless the Secret stored for the service has this access.

Authenticating with tsm CLI as of 2019.2 release of Tableau Server should not require entering a password if the privileged account has the following permissions:

- Member of the TSM-authorized group, which is the local Administrators group on the Windows computer
- Running the command(s) locally on the Tableau Server that is running the Tableau Server Administration Controller service. By default, the Tableau Server Administration Controller service is installed and configured on the initial node in a distributed deployment.

[reference](https://help.tableau.com/current/server/en-us/tsm.htm#Authenti)

# Setup

# Create Script

1. Navigate to **Admin | Scripts**
2. Enter name: **Tableau Service - Dependency Script**
3. Description: **Tableau Service dependency script to update service credential**
4. Category: **Dependency**
5. Script: **Copy and Paste** the provided script [tableau-service-dependency.ps1](tableau-service-dependency.ps1)
6. Click **OK**

# Create Dependency Changer

1. Navigate to **Admin | Remote Password Changing**
2. Navigate to **Configure Dependency Changers**
3. Create a **Create New Dependency Changer**
4. Complete the form according to table below:

    | Field           | Value                      |
    | --------------- | -------------------------- |
    | Type            | PowerShell Script          |
    | Scan Template   | Windows Service            |
    | Name            | **Tableau Service Changer** |
    | Description     | Leave blank                |
    | Port            | Leave blank                |
    | Wait(s)         | Leave at 0                 |
    | Enabled         | Leave checked              |
    | Create Template | Leave checked              |

5. Click **Scripts** tab
6. **Scripts** drop-down select PowerShell created in previous step
7. **Arguments** paste the following: `$MACHINE $PASSWORD`
8. Click **Save**

> **NOTE** If a privileged account is required use the following arguments: `$MACHINE $PASSWORD $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD`.

# Add to Secret

1. Navigate to desired Secret
2. Navigate to **Dependencies** tab
3. Click on **New Dependency**
4. Drop-down for **Type** select the dependency created in the previous step (should be under **Standard** section)
5. Use **Dependency Group** drop-down to select a current group or create a new one
6. Creating a new one provide the **New Group Name** and **New Group Site Name** (drop-down selection)
7. The **ServiceName** can be used for labeling the dependency if you want to put *Tableau* or any value
8. Select **Run As** secret if needed
9. Enter **Machine Name** as the Tableau Server to update

# tableau-service-dependency.ps1

```powershell
# Expected arguments: $MACHINE $PASSWORD $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD
$server = $args[0]
$password = $args[1]
$privAccount = $args[2], $args[3] -join '\'
$privPassword = ConvertTo-SecureString -String $args[4] -AsPlainText -Force
$privCred = [pscredential]::new($privAccount,$privPassword)

$tsmPath = 'C:\Program Files\Tableau\Tableau Server\<version>\tsm.exe'

$scriptBlock = [scriptblock]{
    & "$using:tsmPath configuration set -k service.runas.password -v `"$($using:password)`""
    & "$using:tsmPath pending-changes apply"
}

$invokeParams = @{
    ComputerName = $server
    Credential   = $privCred
    ScriptBlock  = $scriptBlock
}
Invoke-Command @invokeParams
```
