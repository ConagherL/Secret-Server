# Introduction

This document provides the details for configuring a dependency changer for your SQL Server Logins utilized by Idera SQLdm for monitoring.

# SQLdm Requirements

The method used to perform the change against SQLdm is the PowerShell snap-in that ships with the SQLdm Windows Console, [sqldmsnapin](http://wiki.idera.com/x/CgE1).

The commands utilized for this dependency changer:

- `New-SQLdmDrive`
- `Set-SQLdmMonitoredInstance`

You can find these commands documented by Idera [here](http://wiki.idera.com/display/SQLDM/PowerShell+Cmdlets+for+SQL+Diagnostic+Manager).

> **Limitation**: Idera does not provide a cmdlet to perform validation that the credential was applied fully for the configuration.

# Secret Server Requirements

You will have to enable and configure CredSSP for Secret Server or Distributed Engine nodes. You can find documentation on this process [here](https://docs.thycotic.com/ss/authentication/configuring-credssp-for-winrm-with-powershell).

You will also need to install the SQLdm Windows Console on the Secret Server or Distributed Engine node(s) to have access to the PowerShell snap-in noted previously.

# Secret Server Template

This changer is only required for SQL Logins that are utilized by SQLdm to monitor a given SQL Server instance. The template in Secret Server recommended is the **SQL Server Account** template. This template handles the RPC and Heartbeat functionality automatically for you, out of the box.

# Create Script

1. Navigate to **Admin | Scripts**
2. Enter name: **Idera SQLdm Dependency**
3. Description: **Script for rotating SQL Login for SQLdm monitoring connection**
4. Category: **Dependency**
5. Script: **Copy and Paste** the script [idera-sqldm-dependency.ps1](idera-sqldm-dependency.ps1)
6. Click **OK**

# Create Dependency

_The SQLdm snap-in requires that a PSDrive be created. This PSDrive has to be created with a credential that has proper access to the SQLdm repository database._

1. Navigate to your desired secret
2. Navigate to **RPC** tab
3. Add a SQL Login secret that has proper rights to the SQLdm repository database
4. Navigate to **Dependencies** tab
5. Create a **New Dependency** (_create a dependency group if one does not currently exist_)
6. Click the drop-down for **Type**
7. Select the **Idera SQLdm Dependency** under the **Run PowerShell Script** section
8. Provide a **Dependency Name**
9. Select a **Run As** secret if required according to your Secret Server configuration
10. Enter **2** for **Wait(s)**
11. Enter the SQLdm repository database name in **Machine** field
12. Arguments paste the following: `$[1]$USERNAME $[1]$PASSWORD $USERNAME $PASSWORD $[1]$SERVER $MACHINE $SERVER`
13. Click **Save**

> **Note**: The `$SERVER` is the field on the SQL Server Account template that holds the name of your SQL Server instance of the given SQL Login. If you are using a different template, adjust this field variable accordingly.

> **Note**: The `$MACHINE` is the field used in the dependency configuration; to provide easier access for updating that value, if required.

You should now be able to rotate the password of the SQL Login secret. After the waiting period, the dependency changer will update the SQLdm monitor connection for that SQL Server instance.
