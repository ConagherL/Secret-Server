# Introduction

Automate welcome email to all new SS users.

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
| Body    |  Paste contents of the RPC script [Welcome-Email/Email_Template.html](Welcome-Email/Email_Template.html)                                                                               |

### Build Event pipeline
Navigate to Admin | Notification Rules and templates | Rules and create a new rule using the following settings

| Field       | Value                                                                                           |
| ----------- | ----------------------------------------------------------------------------------------------- |
| Rule Name   | Welcome Email                                                                     |
| Message Type | Event Pipeline Send Email Task                                               |
| Template    | Welcome Email                                                                                      |



# Tested on version 11.3
