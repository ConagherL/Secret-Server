# Introduction

This documents provides the details for configuring a dependency changer for the credentials managed in VEEAM Backup and Replication software. How you handle accounts for Windows and Linux can vary. This specific use case follows the pattern that a Windows and Linux credential are the same, with the exception Windows will have `domain\` and Linux will not.

The script is written in a manner that lets you control whether you want to rotate the password for both types or just Windows.

# VEEAM PowerShell Snap-in

VEEAM utilizes a [PowerShell Snap-in](https://helpcenter.veeam.com/docs/backup/powershell/getting_started.html) that is included in the [installation media](https://www.veeam.com/kb1489). This script can be modified to run locally on the web node or Distributed Engine, or against a VEEAM server that already has the snap-in installed.

# Create Script

1. Navigate to **Admin | Scripts**
2. Enter name: **VEEAM Dependency**
3. Description: **Script for rotating credential in VEEAM**
4. Category: **Dependency**
5. Script: **Copy and Paste** the provided script [veeam-dependency-remote.ps1](veeam-dependency-remote.ps1)
6. Click **OK**

# Create Dependency

1. Navigate to your desired secret
2. Navigate to **Dependencies** tab
3. Create a **New Dependency** (_create a dependency group if one does not currently exists_)
4. Click the drop down for **Type**
5. Select the **VEEAM Dependency** under the **Run PowerShell Script** section
6. Provide a **Dependency Name**
7. Select a **Run As** secret if required according to your Secret Server configuration
8. Enter **5** for **Wait(s)**
9. Arguments enter `$SERVER $PASSWORD`
10. Click **Save**
