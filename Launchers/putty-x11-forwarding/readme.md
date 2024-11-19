# Introduction

This document provides the details for creating a custom Launcher for Putty that includes use of X11 forwarding. Please note that this does use the built in putty launcher that comes with Protocol Handler. By default, the built-in launcher does not enable X11 forwarding. 

## Template

The built-in template that is named "Unix Account (SSH)" can be leveraged for this launcher. We recommend copying this template and then renaming it appropriately to something like "Unix Account (SSH) - X11"


# Create Launcher (Non Proxied, Direct Connection)

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `X11F Direct`
1. Enter the **Process Name**: `C:\Program Files\Thycotic Software Ltd\Secret Server Protocol Handler\putty.exe`
1. Enter the **Process Arguments**: `-ssh "$USERNAME"@"$MACHINE" -pw $PASSWORD -X`
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**


# Configure Template Launcher (Non Proxied, Direct Connection)

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select X11F Direct for **Launcher Type to use**
1. Set **Host** to `Machine`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Leave **Port** as 22 
1. Click **Save**

Create a secret and test/verify the launcher functions properly.


# Create Launcher (Proxied Connection)

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. For **Launcher Type** Choose Proxied SSH Process
1. Enter a **Launcher Name** ex: `X11F Proxied`
1. Enter the **Process Name**: `C:\Program Files\Thycotic Software Ltd\Secret Server Protocol Handler\putty.exe`
1. Enter the **Process Arguments**: `-ssh "$USERNAME"@"$HOST" -pw $PASSWORD -X`
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**

# Configure Template Launcher (Proxied Connection)

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select X11F Direct for **Launcher Type to use**
1. Set **Host** to `Host`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Leave **Port** as 22 
1. Click **Save**

For this launcher, you may need to add the Host field on the template. Create a secret and test/verify the launcher functions properly.