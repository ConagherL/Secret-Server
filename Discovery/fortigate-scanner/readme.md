# Introduction

This scanner can help find accounts on Fortigate devices

## Prerequisites

Connecting to the devices through SSH must be permitted and the account that is used to Discovery the accounts on each device must have root access or the ability to query users on the devices.

## Installation

1. Apply Discovery script attached:
   - **ADMIN** > **Scripts**
   - We named ours: Fortigate Scanner
2. Configure Scan Template:
    - **ADMIN** > **Discovery** >  **Configuration** > **Extensible Discovery** > **Configure Scan Templates** >
    - **Accounts** > **Create New Scan Template**
    - **Name** > Fortigate Accounts
    - **Scan Type** > Find Local Accounts
    - **Parent Scan Template** > Account (Basic)

For the field names, fill out `Machine`, `Username`, and `Password` and click **Save**

**Note** the Machine field will be matched up to the parent field of Resource

3. Configure Discovery Scanner:
    - **ADMIN** > **Discovery** > **Configuration** > **Extensible Discovery** > **Scanners** >
    - **Accounts** > **Create New Scanner**
    - **Name** > Fortigate Scanner
    - **Description** > Fortigate Scanner
    - **Discovery Type** > Find Local Accounts
    - **Base Scanner** > Powershell Discovery
    - **Input Template**: Computer
    - **Output Template**: Fortigate Account
    - **Script**: Fortigate Scanner
    - **Arguments**: $Target $[1]$Username $[1]$Password

4. Adding the Scanner

When configuring Unix discovery, configure it as you normally would do. After you have set up Discovery, go to **Scanner Settings** and alter the Find Accounts section to include the Fortigate Scanner

5. Run Discovery
    - The new scanner will find Accounts on the Fortigate devices
