# Introduction

This document provides the details for having Secret Server manage your passwords for Oracle Cloud accounts. Adjustments may be needed based on the provider/service in use within Oracle Cloud.

# Permissions

Oracle Cloud allows local, privileged, accounts (aka admins) to access the API. In configuring the Remote Password Changer, **it does not require** a privileged account to be utilized. Each secret will have the required permission to connect using the API.

# Setup

## Create Scripts

Navigate to **Admin | Scripts** and create a script for the HB and RPC using the details below.

### Oracle Cloud HB

| Field       | Value                                                          |
| ----------- | -------------------------------------------------------------- |
| Name        | Oracle Cloud Heartbeat                                         |
| Description | Oracle Cloud API call for heartbeat                            |
| Category    | Heartbeat                                                      |
| Script      | Paste contents of the [oraclecloud-hb.ps1](oraclecloud-hb.ps1) |
|             |                                                                |

### Oracle Cloud RPC

| Field       | Value                                                            |
| ----------- | ---------------------------------------------------------------- |
| Name        | Oracle Cloud RPC                                                 |
| Description | Oracle Cloud API call for RPC                                    |
| Category    | Password Changing                                                |
| Script      | Paste contents of the [oraclecloud-rpc.ps1](oraclecloud-rpc.ps1) |

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
2. Click **Configure Password Changers**
3. Click **New**
4. Provide following details:

    | Field                 | Value             |
    | --------------------- | ----------------- |
    | Base Password Changer | PowerShell Script |
    | Name                  | Oracle Cloud      |

5. Click **Save**
6. Click drop-down under _Verify Password Changed Commands_, select **Oracle Cloud Heartbeat**
7. Enter following for **Script Arguments**: `$URL $USERNAME $PASSWORD`
8. Click drop-down under _Password Change Commands_, select **Oracle Cloud RPC**
9. Enter following for **Script Arguments**: `$URL $USERNAME $PASSWORD $NEWPASSWORD`
10. Click **Save**

# Create Oracle Cloud Template

1. Navigate to **Admin | Secret Templates**
2. Under **Import Secret Templates** copy/paste the [oraclecloud_template.xml](oraclecloud_template.xml)
3. Click **Import**
4. Click **Configure Password Changing**
5. Click **Edit**
6. Check box for **Enable Remote Password Changing**
7. Adjust the **Retry Interval** and **Maximum Attempts** to your requirements
8. Check box for **Enable Heartbeat**
9. Adjust the **Heartbeat Check Interval** to your requirements.
10. Click drop-down for **Password Type to use**, select **Oracle Cloud**
11. Click drop-down for **Domain**, select **URL**
12. Confirm selections for **Password** and **User Name** are set correctly

Proceed to create a new secret and test/verify the HB and RPC function correctly.
