# Checkout only during Time Window

# Requirement

Secrets only accessible during a specific time window, considering time zone differences.

# Event Pipeline Configuration

Create an Event Pipeline Policy, then create a Pipeline based on the following setup:

| | |
---------------- | ---------------- |
| Trigger(s) | Pre-Checkout |
| Filter(s) | Based on requirements and customer needs. Test/PoC was done using “Site” filter, so that will mean this pipeline kicks in on any secret set to the filtered site if it has Checkout enabled. |
| Task(s) | Run Script [validate-timeframe.ps1](validate-timeframe.ps1) |

# Folder/Secret Configuration

- Secret Policy was created that required Checkout. This policy was assigned at the folder level and all secrets created during testing inherited that policy.
- Created two secrets with varying templates to verify logic and effectiveness.

# Task settings utilized

- Script: Select the script as it was saved under Admin | Scripts
- Run Secret: You will need to set this to a secret that can execute PowerShell (if Run Site also configured the secret must have access to execute on the Distributed Engine server(s))
- Run Site: Set to the desired site (Run Secret configuration dependent upon have access to the site node/DE)

# Script Arguments

- All time formats can be done using “hh:mm tt” (e.g. 8:00 AM)
- Provide the start and end time for the window of availability desired.
- Provide the full time zone name (see note below)

> **Note:** Time zone value is the ID as it is returned from “System.TimeZoneInfo]::GetSystemTimeZones()” in PowerShell. This value generally follows the known names of time zones e.g. Eastern Standard Time, Pacific Standard Time. However, be aware that not all time zones in Windows have a formal name or a recognized name, so have the customer verify on one of their servers. Culture or Language that is set on the installation of Windows may affect this value being properly found. Example on one is UTC, the ID for this time zone in Windows is “Dateline Standard Time” but there are also a few other UTC offsets. Always verify this, just in case.

# Example Script Task configuration with arguments

> Screenshots based on [eventpolicy_checkoutwindow.json](eventpolicy_checkoutwindow.json)

![image](https://user-images.githubusercontent.com/11204251/107519928-751bc800-6b76-11eb-8ece-f01c665c8c6b.png)

Sample Error message that is seen when checkout is not within a set timeframe:

![image](https://user-images.githubusercontent.com/11204251/107519876-659c7f00-6b76-11eb-92a9-1166eb949f4d.png)