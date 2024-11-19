# Introduction

This document provides the details for having Secret Server manage your passwords for Couchbase accounts.

## Permissions

Couchbase Cluster API endpoint used for changing passwords is **only accessible** for the roles that allow access to the cluster web UI.

> **Note**: Accounts that are limited to data access at the bucket level, not assigned `Application Access` role, will not work with this RPC/HB method.

## Couchbase Cluster URLs

Couchbase Clusters provide the ability for users to connect using any of the nodes within the cluster. The script has been written to support use of a single secret for **each cluster**. You can create a launcher for Couchbase Clusters using documentation [here](../../launchers/couchbase).

This will allow you to create one secret for each Couchbase Cluster and then enter the URL for each node into the URL field as a comma-separated list. Example: `http://10.10.10.65:5191, http://10.10.10.66:5191, http://10.10.10.67:5191`. (_Ensure there is a space after the comma.)

# Setup

## Create Scripts

Navigate to **Admin | Scripts** and create a script for the HB and RPC using the details below.

### Couchbase HB

| Field       | Value                                                      |
| ----------- | ---------------------------------------------------------- |
| Name        | Couchbase Heartbeat                                        |
| Description | Couchbase Cluster API call for heartbeat                   |
| Category    | Heartbeat                                                  |
| Script      | Paste contents of the [couchbase-hb.ps1](couchbase-hb.ps1) |

### Couchbase RPC

| Field       | Value                                                        |
| ----------- | ------------------------------------------------------------ |
| Name        | Couchbase RPC                                                |
| Description | Couchbase Cluster API call for RPC                           |
| Category    | Password Changing                                            |
| Script      | Paste contents of the [couchbase-rpc.ps1](couchbase-rpc.ps1) |

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
2. Click **Configure Password Changers**
3. Click **New**
4. Provide the following details:

    | Field                 | Value             |
    | --------------------- | ----------------- |
    | Base Password Changer | PowerShell Script |
    | Name                  | Couchbase         |

5. Click **Save**
6. Click the drop-down under _Verify Password Changed Commands_, select **Couchbase HeartBeat**
7. Enter the following for **Script Arguments**: `$URL $USERNAME $PASSWORD`
8. Click the drop-down under _Password Change Commands_, select **Couchbase RPC**
9. Enter the following for **Script Arguments**: `$URL $USERNAME $PASSWORD $NEWPASSWORD`
10. Click **Save**

# Create Couchbase Account Template

1. Navigate to **Admin | Secret Templates**
2. Under **Import Secret Templates** copy/paste the [couchbase_template.xml](couchbase_template.xml)
3. Click **Import**
4. Click **Configure Password Changing**
5. Click **Edit**
6. Check the box for **Enable Remote Password Changing**
7. Adjust the **Retry Interval** and **Maximum Attempts** to your requirements
8. Check the box for **Enable Heartbeat**
9. Adjust the **Heartbeat Check Interval** to your requirements.
10. Click drop-down for **Password Type to use**, select **Couchbase**
11. Click drop-down for **Domain**, select **URL**
12. Confirm selections for **Password** and **Username** are set correctly
