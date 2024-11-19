# Introduction

This document provides the details for having Secret Server manage your passwords for ServiceNow accounts.

# Permissions

ServiceNow allows local (privileged) accounts, those that are part of the `admin` role, to access the API. In configuring the Remote Password Changer **it does not require** a privileged account to be utilized. Each secret will have the required permission to connect using the API.

# Setup

## Create Scripts

Navigate to **Admin | Scripts** and create a script for the HB and RPC using the details below.

### ServiceNow HB

| Field       | Value                                                        |
| ----------- | ------------------------------------------------------------ |
| Name        | ServiceNow Heartbeat                                         |
| Description | ServiceNow API call for heartbeat                            |
| Category    | Heartbeat                                                    |
| Script      | Paste contents of the [servicenow-hb.ps1](servicenow-hb.ps1) |

### ServiceNow RPC

| Field       | Value                                                          |
| ----------- | -------------------------------------------------------------- |
| Name        | ServiceNow RPC                                                 |
| Description | ServiceNow API call for RPC                                    |
| Category    | Password Changing                                              |
| Script      | Paste contents of the [servicenow-rpc.ps1](servicenow-rpc.ps1) |

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
2. Click **Configure Password Changers**
3. Click **New**
4. Provide following details:

    | Field                 | Value             |
    | --------------------- | ----------------- |
    | Base Password Changer | PowerShell Script |
    | Name                  | ServiceNow        |

5. Click **Save**
6. Click drop-down under _Verify Password Changed Commands_, select **ServiceNow HeartBeat**
7. Enter following for **Script Arguments**: `$URL $USERNAME $PASSWORD`
8. Click drop-down under _Password Change Commands_, select **ServiceNow RPC**
9. Enter following for **Script Arguments**: `$URL $USERNAME $PASSWORD $NEWPASSWORD`
10. Click **Save**

# Create ServiceNow Template

1. Navigate to **Admin | Secret Templates**
2. Under **Import Secret Templates** copy/paste the [servicenow_template.xml](servicenow_template.xml)
3. Click **Import**
4. Click **Configure Password Changing**
5. Click **Edit**
6. Check box for **Enable Remote Password Changing**
7. Adjust the **Retry Interval** and **Maximum Attempts** to your requirements
8. Check box for **Enable Heartbeat**
9. Adjust the **Heartbeat Check Interval** to your requirements.
10. Click drop-down for **Password Type to use**, select **ServiceNow**
11. Click drop-down for **Domain**, select **URL**
12. Confirm selections for **Password** and **User Name** are set correctly

Proceed to create a new secret and test/verify the HB and RPC function correctly.
