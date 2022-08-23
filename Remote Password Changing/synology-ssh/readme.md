# Introduction

This document provides the details for having Secret Server manage your passwords for Synology local accounts via SSH.

# Permissions

The account used within these scripts must be able to connect to the device through SSH in order for these scripts to function.  The Account must be in the Administrator role to change passwords.

# Setup

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
2. Click **Configure Password Changers**
3. Click **New**

### Create New Password Changer

1. Provide following details:

    | Field                 | Value                     |
    | --------------------- | ------------------------- |
    | Base Password Changer | Unix Account Custom (SSH) |
    | Name                  | Synology (SSH)            |

2. Click **Save**

### Enter Commands

1. Under _Verify Password Changed Commands_
2. Enter Commands

    | Order | Field                     | Value             | Pause |
    | ----- | ------------------------- | ----------------- | ----- |
    | 1     | whoami                    | Get Username      | 2000  |
    | 2     | $$CHECKCONTAINS $USERNAME | Validate username | 2000  |

3. Under _Password Changed Commands_
4. Enter Commands

    | Order | Field                                        | Value                                   | Pause |
    | ----- | -------------------------------------------- | --------------------------------------- | ----- |
    | 1     | sudo synouser --setpw $USERNAME $NEWPASSWORD | Change the password for a user Username | 2000  |
    | 2     | $CURRENTPASSWORD                             | Enter password to sudo                  | 2000  |
    | 2     | exit                                         | Exit                                    | 2000  |

# Create Synology (SSH) Template

1. Navigate to **Admin | Secret Templates**
2. Under **Import Secret Templates** copy/paste the [synology_ssh_template.xml](synology_ssh_template.xml)
3. Click **Import**
4. Click **Configure Password Changing**
5. Click **Edit**
6. Check box for **Enable Remote Password Changing**
7. Adjust the **Retry Interval** and **Maximum Attempts** to your requirements
8. Check box for **Enable Heartbeat**
9. Adjust the **Heartbeat Check Interval** to your requirements.
10. Click drop-down for _Password Type to use_, select **Synology (SSH)**
11. Click drop-down for _Machine Name_, select **Machine**
12. Click drop-down for _User Name, select **Username**
13. Click drop-down for _Password_, select **Password**
14. Click **Save**

Proceed to create a new secret and test/verify the HB and RPC function correctly.
