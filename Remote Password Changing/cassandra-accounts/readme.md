# Introduction

This document provides the details for configuring Secret Server to manage your Cassandra account passwords.

# Permissions

This configuration will use CQL language, calling ALTER USER command. Cassandra allows a user to change their password.

# Prerequisites

This process is written using Python and Cassandra's `cassandra-driver` package. Python and PIP are required on the web node or Distributed Engine(s).

> Tested on Python 3.8.5.

# Setup

## Install Python

Install Python on the required servers. Use the customized installation option and ensure the following are checked:

- Add Python 3.x to PATH
- pip
- for all users (requires elevation)
- Install for all users (_under Advanced Options_)

The full path for the `python.exe` will be needed for the script. The default location for Python on Windows will be `C:\Program Files (x86)\Python<version>-32\python.exe`. This path needs to be updated in the script below.

### Install cassandra-driver

Open a PowerShell or Command Prompt as Administrator and run the command below to install the driver:

```powershell
pip install cassandra-driver
```

## Create Scripts

Navigate to **Admin | Scripts** and create a script for the HB and RPC using the details below.

### Cassandra HB

| Field       | Value                                                      |
| ----------- | ---------------------------------------------------------- |
| Name        | Cassandra Heartbeat                                        |
| Description | Cassandra HB utilizing Python                              |
| Category    | Heartbeat                                                  |
| Script      | Paste contents of the [cassandra-hb.ps1](cassandra-hb.ps1) |

### Cassandra RPC

| Field       | Value                                                        |
| ----------- | ------------------------------------------------------------ |
| Name        | Cassandra RPC                                                |
| Description | Cassandra RPC utilizing Python                               |
| Category    | Password Changing                                            |
| Script      | Paste contents of the [cassandra-rpc.ps1](cassandra-rpc.ps1) |

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
2. Click **Configure Password Changers**
3. Click **New**
4. Provide the following details:

    | Field                 | Value             |
    | --------------------- | ----------------- |
    | Base Password Changer | PowerShell Script |
    | Name                  | Cassandra         |

5. Click **Save**
6. Click the drop-down under _Verify Password Changed Commands_, select **Cassandra Heartbeat**
7. Enter the following for **Script Arguments**: `$SERVER $PORT $USERNAME $PASSWORD`
8. Click the drop-down under _Password Change Commands_, select **Cassandra RPC**
9. Enter the following for **Script Arguments**: `$SERVER $PORT $USERNAME $PASSWORD $NEWPASSWORD`
10. Click **Save**

# Create Cassandra Account Template

1. Navigate to **Admin | Secret Templates**
2. Under **Import Secret Templates** copy/paste the [cassandra_template.xml](cassandra_template.xml)
3. Click **Import**
4. Click **Configure Password Changing**
5. Click **Edit**
6. Check the box for **Enable Remote Password Changing**
7. Adjust the **Retry Interval** and **Maximum Attempts** to your requirements
8. Check the box for **Enable Heartbeat**
9. Adjust the **Heartbeat Check Interval** to your requirements.
10. Click the drop-down for **Password Type to use**, select **Cassandra**
11. Click the drop-down for **Domain**, select **Server**
12. Confirm selections for **Password** and **Username** are set correctly

Proceed to create a new secret, and test/verify the HB and RPC function correctly.
