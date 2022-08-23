# Introduction

This documents provides details on a revised version of the KB support article on [Changing SQL Server service accounts without restarting](https://thycotic.force.com/support/s/article/Change-SQL-service-account-without-restarting-the-SQL-service).

# Requirements

This script utilizes a privilege account so the secret this is **_setup will need an associated secret added to the secret_**. Access will only be the Windows Server and not with SQL Server itself.

# Troubleshooting

`SQLWMI` is part of SMO with SQL Server. This exists on every installed SQL Server instance via the SQL Server Configuration Manager (SSCM), newer versions of SQL Server no longer allow you to not install this tooling. Just like WMI there are cases where this can "break" and is commonly found when multiple versions of SQL Server are installed on the same machine. **Especially** if they installed a higher version first, and then installed a lower version such as SQL Server 2016 and then installed SQL Server 2012.

If running the dependency script you see the following error with a customer:

> Failed to update `<service name>` on `<target computer>`. The following excpetion occurred while trying to enumerate the collection: "An exception occurred in SMO while trying to manage a service.".

This can happen when `SQLWMI` is jacked up in some manner. Ask the customer to access that target and verify SSCM can be opened for that version of SQL Server they are trying to manage. (If they have multiple versions, you need to open SSCM associated with the highest version found.) If the target server is having issues you are going to see WMI errors showing up when they open SSCM.

If this occurs they can solve the issue following this MS doc: [Error message when you open SSCM](https://docs.microsoft.com/en-us/troubleshoot/sql/tools/error-message-when-you-open-configuration-manager).

# Secret Server Template

No custom template is required for this changer.

# Create Script

1. Navigate to **Admin | Scripts**
2. Enter name: **SQL Server Service Password Rotation**
3. Description: **Script for rotating SQL Server service account- no restart**
4. Category: **Dependency**
5. Script: **Copy and Paste** the provided script [sqlservice-norestart-dependency.ps1](sqlservice-norestart-dependency.ps1)
6. Click **OK**

# Create Dependency Changer

1. Navigate to **Admin | Remote Password Changing**
2. Navigate to **Configure Dependency Changers**
3. Create a **Create New Dependency Changer**
4. Complete the form according to table below:

    | Field           | Value                                    |
    | --------------- | ---------------------------------------- |
    | Type            | PowerShell Script                        |
    | Scan Template   | Windows Service                          |
    | Name            | SQL Server Service Dependency Changer    |
    | Description     | SQL Server service rotation - no restart |
    | Port            | Leave blank                              |
    | Wait(s)         | Leave at 0                               |
    | Enabled         | Leave checked                            |
    | Create Template | Leave checked                            |

5. Click **Scripts** tab
6. **Scripts** drop-down select PowerShell created in previous step
7. **Arguments** paste the following:

    ```powershell
    $MACHINE $SERVICENAME $PASSWORD
    ```

8. Click **Save**

# Add to Secret

1. Navigate to desired Secret
2. Navigate to **Dependencies** tab
3. Click on **New Dependency**
4. Drop-down for **Type** select the dependency created in the previous step (should under **Standard** section)
5. Use **Dependency Group** drop-down to select a current group or create a new one
6. Creating a new one provide the **New Group Name** and **New Group Site Name** (drop-down selection)
7. Provide the **ServiceName** (obtain the service name using following command on the SQL Server target machine: `Get-Service *sql* | Select-Object Name`)
8. Select **Run As** secret if needed
9. Enter **Machine Name** for the target machine

You should now be able to rotate the password of the SQL Server service account and verify the dependency was successful.
