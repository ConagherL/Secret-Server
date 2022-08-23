# DRAFT

# Introduction

This script will Discover the internal accounts present in the Cisco® Identity Services Engine (ISE).   

## Prerequisites

- **Enable** External RESTful Services (ERS) on CISCO ISE.  https://developer.cisco.com/docs/identity-services-engine/2.6/#!setting-up/cisco-ise
- Privilged account need to be created with required with **ERS Admin Group**  membership. https://developer.cisco.com/docs/identity-services-engine/2.6/#!setting-up/creating-ers-admin
- Open 9060 port from Web Server/DE to ISE
- Enable WinRM/CredSSP on Web Servers/DE

# Secret Server Configuration

## Create Script

1. Navigate to **Admin | Scripts**
1. Select **Create New Script**
1. Enter **Name**: `CISCO ISE Login Discovery`
1. Enter **Description**: `Discovery SQL Logins on the target machine`
1. Select **Category**: `Dependency`
1. **Script**: Copy/Paste the provided script [CiscoISE_Discover_InternalUsers.ps1](CiscoISE_Discover_InternalUsers.ps1)

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
