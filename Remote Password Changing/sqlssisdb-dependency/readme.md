# Introduction

This document provides the details to update an Environment Variable for a given SSIS Project. SSIS Project Deployment model allows a project to have Environment Variables created and these can be used with any SSIS package that is part of that project.

# Permissions

The stored procedure used for this process is within the SSISDB database. The exact permissions required are documented [here](https://docs.microsoft.com/en-us/sql/integration-services/system-stored-procedures/catalog-set-environment-variable-value-ssisdb-database).

# Setup

## Create Scripts

Navigate to **Admin | Scripts** and create a SQL Script for the dependency changer.

### Script

| Field       | Value                                                                         |
| ----------- | ----------------------------------------------------------------------------- |
| Name        | `SSISDB Environment Script`                                                   |
| Description | Updates the secure string values for SSISDB Environment Variables             |
| Category    | Dependency                                                                    |
| Script      | Paste contents of the script below                                            |
| Connection  | SQL Server Account                                                            |
| Database    | SSISDB                                                                        |
| Port        | Provide if required                                                           |
| Params      | `@FOLDERNAME`, `@ENVNAME`, `@VARIABLENAME`, `@PASSWORD` (_all as AnsiString_) |

```sql
DECLARE @cmd NVARCHAR(1200)
SET @cmd = 'DECLARE @var sql_variant = N''' + @PASSWORD + '''
EXEC [SSISDB].[catalog].[set_environment_variable_value]
    @variable_name = N''' + @VARIABLENAME + ''',
    @environment_name = N''' + @ENVNAME + ''',
    @folder_name = N''' + @FOLDERNAME + ''',
    @value = @var'
EXEC sp_executesql @cmd
```

# Add Dependency Changer to Secret

1. Navigate to a Secret
1. Click **New Dependency**
1. Type: Select **SSISDB Environment Script** (under **Run SQL Script** section of drop-down)
1. Dependency Group: Create or Select a current one
1. Run As: select a Secret that has permission noted previously
1. Machine Name: SQL Server instance name (_same used to connect via SSMS_)
1. Enter values for the variables:

    | Parameter     | Value                                                      |
    | ------------- | ---------------------------------------------------------- |
    | @FOLDERNAME   | SSISDB Folder name for the project                         |
    | @ENVNAME      | Environment name in the project that contains the variable |
    | @VARIABLENAME | Exact variable name that should be updated                 |
    | @PASSWORD     | `$PASSWORD`                                                |

1. Click **Save**

## Testing

If you wish to test this you can use the following steps.

1. Install or add the Integration Services component to a current SQL Server instance
1. In SSMS, right-click and select `Create Catalog..`
1. Check the box for `Enable CLR Integration` and `Enable automatic execution of Integration Services stored...`
1. Provide the password for the master encryption key (save this if you want to be able to restore this catalog database)
1. Click **OK**.

Once this is finished, open a new query window and run the following script. This script will create (1) folder, (2) environment, and add a sensitive  (3) variable to the environment.

```sql
USE [SSISDB]
DECLARE @folder_id BIGINT
EXEC [SSISDB].[catalog].[create_folder] @folder_name=N'Test Folder', @folder_id=@folder_id OUTPUT
SELECT @folder_id
EXEC [SSISDB].[catalog].[set_folder_description] @folder_name=N'Test Folder', @folder_description=N''
GO
EXEC [SSISDB].[catalog].[create_environment] @environment_name=N'Test Environment 1', @environment_description=N'', @folder_name=N'Test Folder'
GO
DECLARE @var sql_variant = N'password'
EXEC [SSISDB].[catalog].[create_environment_variable] @variable_name=N'TestSecureVar', @sensitive=True, @description=N'', @environment_name=N'Test Environment 1'@folder_name=N'Test Folder', @value=@var, @data_type=N'String'
GO
```

![image](https://user-images.githubusercontent.com/11204251/138183194-072363bd-d01e-4918-b80f-ffdea776a5aa.png)

Each environment created is automatically assigned a certificate and a symmetric key, all created based on the master encryption key for the catalog database. Use the query below to find the certificate and symmetric key (need this for the next query):

```sql
USE [SSISDB]
GO
-- Find the cert and keys used in SSISDB
SELECT * FROM sys.certificates
SELECT * FROM sys.symmetric_keys
```

- Certificate names will be in the format `MS_Cert_Env_<incremented_number>`.
- Symmetric keys will be in a similar format `MS_Enckey_Env_<incremented_number>`.

> If you have multiple environments, identify the cert and key that was just created.

In the following query replace the tags for the certificate and symmetric key identified in the previous query:

```sql
USE [SSISDB]
GO

OPEN SYMMETRIC KEY <MSSymmetricKeyName> DECRYPTION BY CERTIFICATE <MSCertName>;
SELECT e.environment_id
    ,e.environment_name
    ,ev.[name] AS [variable name]
    ,CONVERT(NVARCHAR(1000), DECRYPTBYKEY(ev.sensitive_value)) AS [decryptedValue]
FROM SSISDB.internal.environment_variables AS ev
INNER JOIN SSISDB.internal.environments AS e ON ev.environment_id = e.environment_id
WHERE e.environment_name = 'Test Environment 1'

CLOSE SYMMETRIC KEY <MSSymmetricKeyName>;
```

The above output can be used to verify the sensitive variable was updated properly.
