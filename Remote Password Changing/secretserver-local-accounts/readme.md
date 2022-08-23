# Introduction

Secret Server Local User account(s) are commonly used for various features such as Event Pipelines. This document and scripts provide the details for doing password rotation for those Secrets.

# Permissions

Secret Server REST API at this time is accessible to all accounts. No direct permissions are required within Secret Server for the User Account.

# Prerequisites

The custom scripts utilize the [Thycotic.SecretServer PowerShell module](https://thycotic-ps.github.io/thycotic.secretserver/docs/install), this will need to be installed on all web nodes or Distributed Engines.

> Version 0.37.0+ is required

# Setup

## Create Scripts

Navigate to **Admin | Scripts** and create a script for the HB and RPC using the details below.

### Heartbeat Script

| Field       | Value                                                            |
| ----------- | ---------------------------------------------------------------- |
| Name        | Secret Server Local User Heartbeat                               |
| Description | Script for heartbeat local user                                  |
| Category    | Heartbeat                                                        |
| Script      | Paste contents of the [secretserver-hb.ps1](secretserver-hb.ps1) |

### Password Changer Script

| Field       | Value                                                              |
| ----------- | ------------------------------------------------------------------ |
| Name        | Secret Server Local User RPC                                       |
| Description | Script for password rotation local user                            |
| Category    | Password Changing                                                  |
| Script      | Paste contents of the [secretserver-rpc.ps1](secretserver-rpc.ps1) |

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
1. Click **Configure Password Changers**
1. Click **New**
1. Provide following details:

    | Field                 | Value                        |
    | --------------------- | ---------------------------- |
    | Base Password Changer | PowerShell Script            |
    | Name                  | Secret Server Local User RPC |

1. Click **Save**
1. Click drop-down under _Verify Password Changed Commands_
1. Select **Secret Server Local User HeartBeat**
1. Enter following for **Script Arguments**: `$url $username $password`
1. Click drop-down under _Password Change Commands_
1. Select **Secret Server Local User RPC**
1. Enter following for **Script Arguments**: `$url $username $password $newPassword`
1. Click **Save**

# Create Secret Server Template

1. Navigate to **Admin | Secret Templates**
1. Under **Import Secret Templates**, copy/paste the [secretserver_localuser_template.xml](secretserver_localuser_template.xml)
1. Click **Import**
1. Click **Configure Password Changing**
1. Click **Edit**
1. Check the box for **Enable Remote Password Changing**
1. Adjust the **Retry Interval** and **Maximum Attempts** to your requirements
1. Check the box for **Enable Heartbeat**
1. Adjust the **Heartbeat Check Interval** to your requirements.
1. Click drop-down for **Password Type to use**
1. Select **Local Secret Server User RPC**
1. Click drop-down for **Domain**
1. Select **URL**
1. Confirm selections for **Password** and **User Name** are set correctly

Proceed to create a new secret and test/verify the HB and RPC function correctly.
