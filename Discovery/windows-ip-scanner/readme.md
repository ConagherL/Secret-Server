# Introduction

This scanner can help perform an Scan for Windows Systems based off an IP address range. 

1. Apply Discovery script attached:
   - **ADMIN** > **Scripts**
   - We named ours: IP Address Machine Scanner

2. Configure Discovery Scanner
    - **ADMIN** > **Discovery** > **Configuration** > **Extensible Discovery** > **Scanners** >
    - **Accounts** > **Create New Scanner**
    - **Name** > Windows Machine Scanner - IP Range
    - **Description** > Windows Machine Scanner - IPRange
    - **Discovery Type** > Find Machines
    - **Base Scanner** > Powershell Discovery
    - **Input Template**: Host Range
    - **Output Template**: Computer
    - **Script**: IP Address Machine Scanner
    - **Arguments**: $Target $[1]$Domain


4. Adding the Scanner

When configuring Unix discovery, configure it as you normally would do. After you have set up Discovery, go to **Scanner Settings** and alter the Find Machines section to include the Windows Machine Scanner - IP Range

5. Run Discovery
    - The new scanner will find Windows systems based on an IP range
