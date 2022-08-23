# Introduction

This document provides the details for creating a custom Launcher for Kitty. KiTTY is a fork from version 0.70 of PuTTY, and it is only designed for the Microsoft® Windows® platform.  Kitty client allows to do a Telnet session where you need to submit the user credentials automatically.

# Prerequisites

1. On your destination system, ensure there’s a Telnet server installed listening on port 23. [Free Telnet server](https://www.pragmasys.com/telnet-server/download)
1. Install Kitty on Secret Server, and use the executable [Kitty_Portable.exe](https://github.com/cyd01/KiTTY/releases)
1. Modify the kitty.ini

    Remove the comment on ‘#commanddelay=2’ and set it to ‘commanddelay=1’

    ```console
    #bcdelay=0
    commanddelay=1
    #initdelay=0
    ```

## Template

Please note that with this launcher we simply leverage default templates. We use the default "Windows Account" template. Consider duplicating this template and naming it appropriately for use with Kitty (Ex: Windows Account Telnet). Add a new field to the template called **ShortName**, which replaces the hostname of the target server.

# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `Kitty Launcher`
1. Enter the **Process Name**: `\\<host>\<Share>\kitty_portable.exe`
1. Enter the **Process Arguments**: `-telnet $Machine -cmd "$ShortName\$Username\n$PASSWORD\n"`
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**

The process name assumes that you're launching kitty from a network share. If being used locally, simply replace the process name with the correct path to your kitty_portable.exe

## Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select Kitty Launcher for **Launcher Type to use**
1. Set **Domain** to `ShortName`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
