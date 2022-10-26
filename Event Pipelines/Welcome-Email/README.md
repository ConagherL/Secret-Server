# Introduction

Automate welcome email to all new SS users. This version has been tested on 11.3

## Permissions

Account creating this requires these role permissions "Administer Pipelines", "Administer Inbox"

## Setup

### Build Welcome Email
Navigate to Admin | Notification Rules and templates | Templates and create a new template using the following settings

| Field       | Value                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------- |
| Template Name   | Welcome Email                                                                     |
| Type | Email                                              |

Once created, modify the following fields

| Field       | Value                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------- |
| Language  | English                                                                 |
| Subject | Welcome to Secret Server - $TargetUser.DisplayName                                              |
| Body    |  Paste contents of the RPC script [Email_Template.html](Email_Template.html)                                                                               |

### Build Event Policy
Navigate to Admin | Notification Rules and templates | Rules and create a new rule using the following settings

| Field       | Value                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------- |
| Action  | Create New Policy                                                                     |
| Policy Name | Welcome Email for All New users                                           |
| Policy Description | Generates a welcome email with relevant information                                             |
| Policy Type   | User                                                                                      |

#### Target
Set target as the AD/SS Local group specified that syncs in new users. This will filter the entire policy to only users in this group that will be enabled

### Build Event Pipeline
Once the policy has been created. Click Add Pipeline | Create New Pipeline

| Field       | Value                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------- |
| Trigger  | Enable                                                                    |
| Filter | NA                                          |
| Tasks | Target User: Send Email to Target User                                            |
| Email Format  | Email Template                                                                                 |
| Email Template  | Welcome Email                                                                              |
| Pipeline Name  | User-Welcome Email                                                                            |

