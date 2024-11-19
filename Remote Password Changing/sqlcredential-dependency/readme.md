# Introduction

This document provides the details for having Secret Server manage the password for a [SQL Credential object](https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/create-a-credential).

# Permissions

A login used with a SQL Credential does not require it to be a physical login on the SQL Server instance. In most cases you will need to use a Run As account on the dependency changer that has permissions to both:

- Login to SQL Server instance
- Minimum `ALTER ANY CREDENTIAL` ([more info](https://docs.microsoft.com/en-us/sql/relational-databases/security/authentication-access/create-a-credential#Permissions))

# Setup

## Create Scripts

Navigate to **Admin | Scripts** and create a SQL Script for the dependency changer.

### Script

| Field       | Value                                                                |
| ----------- | -------------------------------------------------------------------- |
| Name        | Update SQL Credential                                                |
| Description | T-SQL method for updating a SQL Credential                           |
| Category    | Dependency                                                           |
| Script      | Paste contents of the [update-credential.sql](update-credential.sql) |
| Connection  | SQL Server Account                                                   |
| Database    | master                                                               |
| Port        | provide if required                                                  |
| Params      | `@DOMAIN`, `@USERNAME`, `@PASSWORD` (_all as AnsiString_)            |

## Create Dependency Changer

1. Navigate to **Admin | Remote Password Changing**
1. Click **Create New Dependency Changer**
1. Provide following details:

    | Field         | Value                            |
    | ------------- | -------------------------------- |
    | Type          | SQL Script                       |
    | Scan Template | SQL Dependency (Basic)           |
    | Name          | **SQL Server Credential Update** |
    | Description   | Update a SQL Credential          |
    | Port          | update if required               |
    | Wait(s)       | leave default                    |

1. Click Scripts Tab
1. Script: Select `Update SQL Credential` (created in previous section)
1. Click Parameters Tab
1. Associate `$DOMAIN`, `$USERNAME`, `$PASSWORD` to the matching parameter
1. Click **Save**

# Add Dependency Changer to Secret

1. Navigate to a Secret
1. Click **New Dependency**
1. Type: select **SQL Server Credentail Update**
1. Dependency Group: Create or Select a current one
1. Server Name: enter SQL Server instance name (_same used to connect via SSMS_)
1. Run As: Select a Secret that has permission noted previously
1. Machine Name: SQL Server instance name (_same used to connect via SSMS_)

## Testing

If you wish to test this you can use the following steps.

1. Create a test AD user (requires no special rights)
1. Create a SQL Credential on a SQL Server instance

    ```sql
    USE [master]
    GO
    CREATE CREDENTIAL [Test Proxy Credential] WITH IDENTITY = N'lab\testuser', SECRET = N'password'
    GO
    ```

1. Go to SQL Server Agent > Proxies > Operating System (CmdExec) and create a proxy account

    ```sql
    USE [msdb]
    GO
    DECLARE @proxyName NVARCHAR(50) = 'Test Proxy User'
    DECLARE @credName NVARCHAR(50) = 'Test Proxy Credential'
    EXEC msdb.dbo.sp_add_proxy
        @proxy_name= @proxyName,
        @credential_name= @credName,
        @enabled=1
    GO

    EXEC msdb.dbo.sp_grant_proxy_to_subsystem
        @proxy_name= @proxyName,
        @subsystem_id=3
    GO
    ```

1. Create a SQL Agent job that will use the proxy account and issue `whoami`, it will also print the output to the job history in order to visibly see the proxy account was used.

    ```sql
    USE [msdb]
    GO
    DECLARE @jobId BINARY(16)
    EXEC msdb.dbo.sp_add_job
        @job_name=N'Test User Proxy - cmd',
        @enabled=1,
        @owner_login_name=N'sa',
        @job_id = @jobId OUTPUT
    EXEC msdb.dbo.sp_add_jobstep
        @job_id=@jobId,
        @step_name=N'whoami',
        @step_id=1,
        @os_run_priority=0, @subsystem=N'CmdExec',
        @command=N'whoami',
        @flags=32,
        @proxy_name=N'Test Proxy User'
    EXEC msdb.dbo.sp_update_job
        @job_id = @jobId,
        @start_step_id = 1
    EXEC msdb.dbo.sp_add_jobserver
        @job_id = @jobId,
        @server_name = N'(local)'
    ```

1. Run the Job to verify current password functions properly
1. Create Secret and configure Dependency Changer
1. Run Dependency Changer with current password
1. Run Agent job to confirm
1. Run RPC to change password in AD
1. Run Agent job to confirm
