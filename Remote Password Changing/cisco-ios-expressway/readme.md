# Introduction

This document provides the details for having Secret Server manage your passwords for Cisco IOS Expressway devices. It leverages the Posh SSH module and this is a requirement for these scripts to function. These scripts may be used for other devices that use Posh SSH.

# Permissions

The account used within these scripts must be able to connect to the Cisco IOS Expressway device through SSH in order for these scripts to function.

# Setup

## Create Scripts

Navigate to **Admin | Scripts** and create a script for the HB and RPC using the details below.

### Cisco IOS Expressway HB

| Field       | Value                                                                |
| ----------- | -------------------------------------------------------------------- |
| Name        | Cisco IOS Expressway HB                                              |
| Description | Cisco IOS Expressway Heartbeat                                       |
| Category    | Heartbeat                                                            |
| Script      | Paste contents of the [PoshSSH-HeartBeat.ps1](PoshSSH-HeartBeat.ps1) |

### Cisco IOS Expressway RPC

| Field       | Value                                                                              |
| ----------- | ---------------------------------------------------------------------------------- |
| Name        | Cisco IOS Expressway RPC                                                           |
| Description | Cisco IOS Expressway RPC                                                           |
| Category    | Password Changing                                                                  |
| Script      | Paste contents of the [PoshSSH-ChangePWTemplate.ps1](PoshSSH-ChangePWTemplate.ps1) |

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
2. Click **Configure Password Changers**
3. Click **New**
4. Provide following details:

    | Field                 | Value                    |
    | --------------------- | ------------------------ |
    | Base Password Changer | PowerShell Script        |
    | Name                  | Cisco IOS Expressway RPC |

5. Click **Save**
6. Click drop-down under _Verify Password Changed Commands_, select **Cisco IOS Expressway Heartbeat**
7. Enter following for **Script Arguments**: `$Target $Username $Password`
8. Click drop-down under _Password Change Commands_, select **Cisco IOS Expressway Heartbeat**
9. Enter following for **Script Arguments**: `$Target $Username $Password $NewPassword`
10. Click **Save**

# Create Template

Please note that with this password changer, we simply leverage default templates. Consider taking the default "Unix Account (SSH)" and duplicating it. Then, modify the template to include the parameters above where the **Machine** field would be substituted for **Target**

Proceed to create a new secret and test/verify the HB and RPC function correctly.

## Dependency Changer

An additional Dependency Changer script was written and can be found here [PoshSSHDependencyChanger.ps1](PoshSSHDependencyChanger.ps1)
