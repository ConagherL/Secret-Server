# Custom Secret Server Reports

This repository's content is for internal reference to share various SQL scripts that have been tested as valid custom reports for Secret Server.

## Adding

When adding reports to this repository a header as provided below should be added to the script (`.sql`) file.

```sql
/*
.PURPOSE
Pull the Item name/display name along with assigned Metadata details
*/
```

## Report List

> Please update this as you add report scripts.

### System

| Name                   | Description                                                                                        |
| ---------------------- | -------------------------------------------------------------------------------------------------- |
| [User Session Details] | View session details of user connections, provides IP of the connection and node they connected to |

### Discovery

| Name                                   | Description                                                                                                                                                                                                                                           |
| -------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| [Local Accounts]                       | Get list of local accounts found in discovery scanning                                                                                                                                                                                                |
| [Dependency Accounts]                  | Get list of dependencies found during discovery scanning                                                                                                                                                                                              |
| [Dependency Accounts - Unmanaged]      | Get list of dependencies found during discovery scanning that are not managed                                                                                                                                                                         |
| [Scan Errors - by Count]               | Group Errors by count on unsuccessful scans, with filter for start and enddate                                                                                                                                                                        |
| [Scan Errors Count - by Computer Name] | Group Errors by count on unsuccessful scans, by Computer Name with filter on start and end date                                                                                                                                                       |
| [Dependency Computer List - Unamanged] | List unmanaged Dependencies computer details, with found and last poll date                                                                                                                                                                           |
| [Computer and Account details]         | Computer and Account details from discovery scan                                                                                                                                                                                                      |
| [Dependency Details]                   | Gets list of dependencies and provide details on computer, account and dependency type                                                                                                                                                                |
| [Account Scan - Details]               | Account scan results with Scan Template, for managed and unmanaged                                                                                                                                                                                    |
| [Pulling Additional Data - JSON]       | Query parses the JSON data stored in AdditionalData column of tbComputerAccount. Only supported on SQL Server 2016+ and Azure SQL. Uses filter to focus on specific Scan Template - example is for Active Directory pulling additional attribute data |
| [Discovery Scan Status]                | Query results show the start and end time for Discovery Scans                                                                                                                                                                                         |
| [Computer Scan Status]                 | Query results show the start and end time for Computer Scans                                                                                                                                                                                          |

### Metadata

| Name                  | Description                                                      |
| --------------------- | ---------------------------------------------------------------- |
| [Metadata Basic Info] | Returns basic information for managing Metadata across all items |

### Migration

| Name                  | Description                                                      |
| --------------------- | ---------------------------------------------------------------- |
| [Built-In Templates with Customization]| Returns information on built-in templates that have customizations |
| [Custom Templates] | Returns information on custom templates |
| [Duplicate Secrets with Folder Path] | Returns information on duplicate secrets and includes folder path |
| [Secrets with Checkout, Comment, and Approval] | Returns information on secrets with specific features enabled |


### Secrets - Associated

| Name                             | Description                                                |
| -------------------------------- | ---------------------------------------------------------- |
| [Associated Secrets by Template] | Get list of Secrets and the associated secrets by Template |

### Secret - Dependencies

| Name                                       | Description                                                                   |
| ------------------------------------------ | ----------------------------------------------------------------------------- |
| [Secret Dependency Status - By Date Range] | Modified version of Secret Dependency Status report, adding date range filter |

### Secret Templates

| Name | Description |
| ---- | ----------- |

### Miscellaneous

| Name | Description |
| ---- | ----------- |
| [Reports Run by Date Range] | Pivoted list of reports based on execution distribution and date range |
| [Reports Run by Day, by Execution] | Total executions by day, by action (viewed or scheduled) |
| [Reports Run by Day] | Total report executions per day |

[Local Accounts]:/discovery/discovery-local-accounts.sql
[Dependency Accounts]:/discovery/discovery-dependency-accounts.sql
[Dependency Accounts - Unmanaged]:/discovery/discovery-dependency-unmanaged.sql
[Scan Errors - by Count]:/discovery/discovery-scan-errors-count.sql
[Scan Errors Count - by Computer Name]:/discovery/discovery-scan-errors-count-computer.sql
[Dependency Computer List - Unamanged]:/discovery/discovery-scan-computer-details.sql
[Computer and Account details]:/discovery/discovery-scan-computer-account-details.sql
[Dependency Details]:/discovery/discovery-dependency-details.sql
[Account Scan - Details]:/discovery/discovery-account-w-scan-template.sql
[Pulling Additional Data - JSON]:/discovery/discovery-additional-data.sql
[Metadata Basic Info]:/metadata/metadata-basic-info.sql
[Discovery Scan Status]:/discovery/discovery-status-discoveryscan.sql
[Computer Scan Status]:/discovery/discovery-status-computerscan.sql
[User Session Details]:/system/user-session-details.sql
[Secret Dependency Status - By Date Range]:/secret-dependencies/secret-dependency-status-by-date-range.sql
[Associated Secrets by Template]:/secrets-associated/associated-secrest-filtered-by-template.sql
[Reports Run by Date Range]:/reports/reports-run-by-date-range.sql
[Reports Run by Day, by Execution]:/reports/reports-run-total-day-execution.sql
[Reports Run by Day]:/reports/reports-run-total-day.sql
[Built-In Templates with Customization]:/Migration/Built-In-Templates-with-Modifications.sql
[Custom Templates]:/Migration/Custom_Templates.sql
[Duplicate Secrets with Folder Path]:/Migration/Duplicate_Secrets_w_FolderPath.sql
[Secrets with Checkout, Comment, and Approval]:/Migration/Secrets-With-Checkout-Req-Comment-Req-Approval-Enabled.sql
