# Introduction

This scanner can help find Services in Windows that are running with local non-domain accounts. Please note that this script is very similar to the "Windows Service" dependency scanner and will still rely on the output template of "Windows Service".

1. Apply Discovery script attached:
   - **ADMIN** > **Scripts**
   - We named ours: Windows Services - LA

2. Configure Discovery Scanner
    - **ADMIN** > **Discovery** > **Configuration** > **Extensible Discovery** > **Scanners** >
    - **Accounts** > **Create New Scanner**
    - **Name** > Windows Services - Local Accounts
    - **Description** > Windows Services - Local Accounts
    - **Discovery Type** > Find Dependencies
    - **Base Scanner** > Powershell Discovery
    - **Input Template**: Windows Computer
    - **Output Template**: Windows Service
    - **Script**: Windows Services - LA
    - **Arguments**: $Machine $[1]$Username $[1]$Password


4. Adding the Scanner

When configuring Active Directory discovery, configure it as you normally would do. After you have set up Discovery, go to **Scanner Settings** and alter the Find Dependencies section to include the Windows Services - Local Account scanner

5. Run Discovery
    - The new scanner will find service accounts that are running as local windows users (non domain)

