# Introduction

This script can be utilized for discovering MySQL Logins on a target machine as part of Discovery in Secret Server. The script provided will connect to a designated MySQL server and query for all local users.

> Note: It will **exclude** built-in MySQL Logins:
> - mysql.infoschema
> - mysql.session
> - mysql.sys

## Prerequisite

### MySQL Net Connector

Net Connector is used to connect to MySQL to run SQL commands against the target MySQL Server.

 - [All In One](https://dev.mysql.com/downloads/windows/installer/)
 - [Net Connector](https://dev.mysql.com/downloads/connector/net/)

> **Note:** Must be installed on all Distributed Engines or Web Servers in the same site.  Tested against version:
>- `MySQL Connector Net 8.0.27 Build .Net 4.8`

MySQL Discovery defaults to port **3306**

### Privileged Account

The script supports using a privileged account to login to the  MySQL Server to find logins.  The account used to run Discovery will be utilized for scanning the target machine for SQL Server installations.  The account required for the scanner will be based on your use case and environment configuration. At a minimum, the scanner needs an account with rights to access SQL Server to pull users.


### MySQL Server Minimum Permission

- MySQL Role: `SecurityAdmin`
- Connecting From: `Distributed Engine Server(s)`


## Secret Server Configuration

### Create Script

1. Navigate to **Admin | Scripts**
1. Select **Create New Script** (_see table below_)
1. Select **OK**

#### Create New Script details

| Field | Value |
| ------------ | -------------------------------- |
| Name | MySQL Login Discovery |
| Description | Discovery MySQL Logins on the target machine |
| Category | Dependency |
| Script | Paste contents of the script [discovery-mysqllogin.ps1](discovery-mysqllogin.ps1) |


### Create Scan Template

1. Navigate to **Admin | Discovery | Extensible Discovery | Configure Scan Templates**
1. Navigate to the **Accounts** tab
1. Select **Create New Scanner** (_see table below_)
1. Select **OK**

#### Create New Scanner details

| Field | Value |
| ------------ | -------------------------------- |
| Name | MySQL Local Account |
| Scan Type | Find Local Accounts |
| Parent Scan Template | Account (Basic) |
| Active | Checked |


| Field | Value | Include In Match |
| ------------ | -------------------------------- | ---- |
| Machine | Machine | X |
| Username | Username | X |
| Password | Passowrd | |


### Create Discovery Scanner

1. Navigate to **Admin | Discovery | Extensible Discovery | Configure Discovery Scanners**
1. Navigate to the **Accounts** tab
1. Select **Create New Scanner** (_see table below_)
1. Select **OK**

#### Create New Scanner details

| Field | Value |
| ------------ | -------------------------------- |
| Name | MySQL Logins |
| Description | Discovery MySQL Logins on MySQL Server |
| Discovery Type | Find Local Accounts |
| Base Scanner | PowerShell Discovery |
| Input Template | Windows Computer |
| Output Template | MySQL Local Account |
| Script | MySQL Login Discovery |
| Script Arguements | `$target $[1]$Username $[1]$Password` |


Adjust the script to match the installed location of the MySQL Net Connector and log location:

```powershell
# Path to the libray MySQL.Data.dll
$mysqlpath = 'C:\Program Files (x86)\MySQL\MySQL Connector Net 8\Assemblies\v4.8\'

# Path to Logging Folder
$logPath = 'C:\temp\scripts'
```

### Update Remote Password Changer

1. Navigate to **Admin | Remote Password Changing**
1. Select **Configure Password Changers**
1. Select **MySQL Account**
1. Select **Configure Scan Template** (_see table below_)


| Field | Value |
| ------------ | -------------------------------- |
| Scan Template to Use | MySQL Local Account |
| Machine | server |
| Username | username |
| Password | password |

Select **Save**


### Create Source Account Scanner

1. Navigate to **Admin | Discovery | Edit Discovery Sources**
1. Navigate to the desired source
1. Navigate to the **Scanner Settings** tab
1. Under **Find Accounts** select **Add New Account Scanner**
1. Select the **My SQL Logins** scanner created in the previous section
1. Under **Secret Credential** select **Add Secret** (Choose appropriate MySQL Discovery secret)
1. Under **Advanced Settings** adjust the **Scanner Timeout (minutes)** value if necessary
1. Select **OK**

## Next Steps

Once the above configuration has been done, you can trigger Discovery to scan your environment to find all the MySQL Logins.
