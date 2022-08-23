# Introduction

This script will authenticate to an IOS device with or without an enabled password then run `show running-config | i user`, read the stream from ssh and extract accounts to be applied to secret server discovery.

## Prerequisites

- Cisco IOS device with local users
- Cisco Account (SSH) to authenticate with
- Cisco Enable Secret (SSH) if necessary
- Powershell Module Posh-SSH installed on the Web Node or Distributed Engine that will be running discovery.

# Secret Server Configuration

## Create Script

1. Navigate to **Admin | Scripts**
1. Select **Create New Script**
1. Enter **Name**: `Cisco IOS Login Discovery`
1. Enter **Description**: `Discovery Cisco IOS Logins on the target machine`
1. Select **Category**: `Dependency`
1. **Script**: Copy/Paste the provided script [discovery_cisco.ps1](discovery-cisco.ps1)

## Create Scan Template

1. Navigate to **Admin | Discovery**
2. Click on **Configuration** tab
3. Click the drop-down **Discovery Configuration Options**
4. Click on **Scan Templates**
5. Click on the **Accounts** tab
6. Click **Create New Scan Template**
7. Configure Discovery Scanner:

- **ADMIN** > **Discovery** > **Extensible Discovery** > **Configure Discovery Scanners** >
- **Local Accounts** > **Create New Scanner**
- **Output Template**: Select scan template from step 2
- **Script**: Select  script from step 1
- **Arguments**: `$target $[2]$username $[2]$password $[3]$password`

4. Configure Takeover

- **ADMIN** > **Remote Password Changing** > **Configure Password Changers** > **+New**
- **Base Password Changer**: Cisco Account Custom (SHH)
- **Name**: Cisco Account Takeover
- **Edit** > Enable **Valid for Discovery Import**

5. Assign Password Changer

- **ADMIN** > **Secret Templates** > **Cisco Account (SSH)** >
- **Edit** > **Configure Password Changing** > **Edit**
- **Password Type to use**: Cisco Account Takeover

6. Add Discovery Source

- **ADMIN** > **Discovery** > **+Create New** > **Unix Discovery Source**
- **Name**: Cisco Networking
- **Scan Range**: IP Address
- Apply prerequisite secret(s) for authentication
- Remove **Unix Non-Daemon User** scanner
- **Add New Local Account Scanner** > Choose scanner from step 3
- Apply **Secret Credentials**
    1. Account to run powershell script
    2. Account to authenticate to Cisco endpoint
    3. Account with enable password if applicable

7. Run Discovery

You can view the accounts found and import those desired for management.
