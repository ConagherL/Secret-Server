# Introduction

This document provides the details for having Secret Server manage your SSH Keys on Juniper JunOS accounts.

## Permissions

# Setup

## Create Password Changer

Navigate to **Admin | Remote Password Changing | Configure Password Changers** and create a new Password changer. The Base for the Password Changer should be **SSH Key Rotation**. Give it an appropriate name.

### Verify Password Change Commands

#### Authenticate As

| Field       | Value       |
| ----------- | ----------- |
| Username    | $USERNAME   |
| Password    | <BLANK>     |
| Key         | $PRIVATEKEY |
| Passphrase  | $PASSPHRASE |

#### Commands

** NONE **

### Password Change Commands

#### Authenticate As

| Field       | Value       |
| ----------- | ----------- |
| Username    | $USERNAME   |
| Password    | <BLANK>     |
| Key         | $PRIVATEKEY |
| Passphrase  | $PASSPHRASE |

#### Commands

| Order | Command                                           | Comment                                               | Pause(MS) |
| ----- | ------------------------------------------------- | ----------------------------------------------------- | --------- | 
| 1     | edit                                              | Enter edit mode                                       | 2000      |
| 2     | edit system login user $USERNAME                  | Edit User                                             | 2000      |
| 3     | set authentication ssh-rsa "$NEWPUBLICKEY"        | Set new SSH Key                                       | 2000      |
| 4     | delete authentication ssh-rsa "$CURRENTPUBLICKEY" | Remove old SSH Key                                    | 2000      |
| 5     | commit                                            | Save Changes (long wait to accomodate large switches) | 30000     |
| 6     | exit                                              | Exit                                                  | 5000      |

# Usage

To use this password changer, duplicate the **Unix Account (SSH Key Rotation - No Password)** template and set **Password Type to use** field to the Password changer created previously.
