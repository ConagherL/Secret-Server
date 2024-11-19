# Introduction

This script will dynamically assign privileged accounts based on the Machine and Username, within a folder structure. This functionality works similar to the discovery Secret Search Filter, but for Privileged accounts.

This document is designed to assist Secret Server administrators in the creation of a solution to automate assigning machine-specific privileged accounts to a set of secrets upon creation. This method leverages a PowerShell script and Event Pipelines to accomplish the automation.

## Details

This solution addresses the challenge of automating assigning a machine-specific privileged account to a newly created secret. This is particularly helpful on non-Active Directory discovery sources, such as *nix and virtualization environments (ESXi), where the privileged account exists on each individual machine (e.g. machine1\ svc_rpc, machine2\svc_rpc and so on).

We will be automating this process so that once the secret is created for the host (via Discovery Rule or manually), the Event Pipeline is triggered to run a script that will call Secret Server, find the machine-specific privileged account then update the new secret assigning the privileged account.

# Requirements

1. Secret Server 10.8+ Professional or higher
1. Secret Server Application Account (used to make API calls)
1. Install Thycotic.SecretServer PowerShell module (on all web nodes/DEs)
1. Add [update-secret-priv-account-v2.ps1](update-secret-priv-account-v2.ps1) script
1. Create Event Pipeline

# Permissions

The Secret Server Application Account for the REST API calls will need the following Folder and Secret permissions:

# Permission

API account utilized will require the following permissions:

| Privileged Secret(s) | Privilege Secret Folder |
| ---------------- | --------------- |
| Edit | Owner |

| Target Secret(s) | Target Secret Folder(s) |
| ---------------- | --------------- |
| Owner | Edit |

# Advanced Configuration Requirement

For the Event Pipeline to function, the advanced setting: **“Event Pipelines: Allow Confidential Secret Fields to be used in Scripts"** must be enabled under the advanced configuration in Secret Server. The application setting will allow confidential secret fields to be used in Event Pipeline scripts, such as `$PASSWORD`. The default value is False.

1. Naviage to `<Secret Server Url>/ConfigurationAdvanced.aspx`
1. Click **Edit** (bottom of page)
1. Find **Event Pipelines: Allow Confidential Secret Fields to be used in Scripts** setting
1. Set the value to **True**
1. Click the **Save** button.

# Create Script

# Script

1. Navigate to **Admin | Scripts**
1. Click the **Create new** under PowerShell tab
1. Enter Name: **Update Secret Privileged Acct**
1. Enter Description as desired
1. Select **Untyped** category
1. Paste contents of the script [update-secret-priv-account-v2.ps1](update-secret-priv-account-v2.ps1)

## Logging

The script is written to log to a physical file that will be created on the web nodes or Distributed Engine(s). You can adjust the `$logFile` variable in the script to adjust the full path. The filename is auto-generated with a timestamp, so each Event Pipeline run will generate a separate file for troubleshooting.

> **No sensitive** data is written to the log file.

# Create Event Pipeline

A pipeline should be created for each field you want to synchronize from the parent secret. The arguments used in the Script Task will determine what field and field values are synchronized.

1. Naviage to **Admin | See All | Actions Category | Event Pipeline Policy**
1. Click the button **Add Policy**
1. Enter Policy Name **Update Secret Privileged Account**
1. Select Policy Type **Secret**
1. Click the button **Create**
1. Click the button **Add Pipeline**
1. Click the radio button **Create New Pipeline**
1. Click the button **Create**
1. Add Secret Triggers:
    - **Secret: Create**
1. Add desired Secret Filters:
    - **Secret has Field** -- select **Machine** for the **Secret Field Name**
    - **Secret has Field** -- select **Host** for the **Secret Field Name** (_if applies_)
1. Add Secret Tasks:
    - **Script Task**
    1. **Script** select **Sync Secrets**
    1. Check box for **Use Site Run As Secret**
    1. Script Args, use one of the following:

        - `"$[ADD:1]$URL" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "$MACHINE" "<Priv Folder ID>" "<priv username>"`
            - Replace `$MACHINE` with `$HOST` or the field name that has the server name in it.
    1. Select desired **Run Site**
    1. Click **No Secret Selected** for **Additional Secret 1** and add the Secret to be used for API authentication.
    1. Click **Save**
1. Set **Pipeline Name** as **Update Secret Privileged Account**
1. Click the button **Save**
