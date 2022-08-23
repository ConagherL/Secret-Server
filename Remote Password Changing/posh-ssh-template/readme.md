# Introduction

This document provides the details for having Secret Server manage your passwords using the powershell rather than the built-in ssh BlackBox libraries this can allow for additional customization. It leverages the [Posh SSH module](https://www.powershellgallery.com/packages/Posh-SSH/) and this is a requirement for these scripts to function. These scripts may be used for other devices that use Posh SSH

# Permissions

The account used within these scripts must be able to connect to the device through SSH in order for these scripts to function.

# Setup

## Install module on server

Install the [Posh-SSH module](https://www.powershellgallery.com/packages/Posh-SSH/) from the PowerShell Gallery as an Administrator.

```powershell
Install-Module Posh-SSH -Scope AllUsers
```

## Customize Scripts

The files provided are examples of changers you can use, but in most cases you will need to customize the commands to match your use case. The scripts are generally configured to send a command, wait for a certain amount of time then issue a new command until complete.

To send a command use the **WriteLine()** method

```powershell
$SSHStream.WriteLine("commands go in here")
$SSHStream.WriteLine("$variables are also valid")
```

Reading output from the stream is done via the **read()** method

```powershell
  $output = $SSHStream.read()
  ```

## Upload Scripts To SecretServer

Navigate to **Admin | Scripts** and create a script for the HB and RPC using the details below.

### PoSH-SSH HB

| Field       | Value                                                                         |
| ----------- | ----------------------------------------------------------------------------- |
| Name        | PoSH-SSH HB                                                                   |
| Description | PoSH-SSH Heartbeat                                                            |
| Category    | Heartbeat                                                                     |
| Script      | Paste  updated contents of the [poshssh-heartbeat.ps1](poshssh-heartbeat.ps1) |

### PoSH-SSH RPC

| Field       | Value                                                                                      |
| ----------- | ------------------------------------------------------------------------------------------ |
| Name        | PoSH-SSH RPC                                                                               |
| Description | PoSH-SSH Password Changer                                                                  |
| Category    | Password Changing                                                                          |
| Script      | Paste updated contents of the [poshssh-changepwtemplate.ps1](poshssh-changepwtemplate.ps1) |

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
2. Click **Configure Password Changers**
3. Click **New**
4. Provide following details:

    | Field                 | Value             |
    | --------------------- | ----------------- |
    | Base Password Changer | PowerShell Script |
    | Name                  | PoSH-SSH RPC      |

5. Click **Save**
6. Click drop-down under _Verify Password Changed Commands_, select **PoSH-SSH Heartbeat**
7. Enter following for **Script Arguments**: `$Target $Username $Password`
8. Click drop-down under _Password Change Commands_, select **PoSH-SSH Heartbeat**
9. Enter following for **Script Arguments**: `$Target $Username $Password $NewPassword`
10. Click **Save**

# Create Template

Please note that with this password changer, we simply leverage default templates. Consider taking the default "Unix Account (SSH)" and duplicating it. Then, modify the template to include the parameters above where the **Machine** field would be substituted for **Target**

Proceed to create a new secret and test/verify the HB and RPC function correctly.

## Dependency Changer

An additional Dependency Changer script was written and can be found here [poshssh-dependencychanger.ps1](poshssh-dependencychanger.ps1)
