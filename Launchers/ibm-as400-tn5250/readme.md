# Introduction

This document provides the details for creating a custom Launcher for TN5250. The launcher associated to this installer can be found here http://tn5250.sourceforge.net. There are many other TN5250 launchers available to download, but this is the only one we have tested currently.

## Template

Please note that with this launcher we simply leverage default templates. We use the default "Windows Account" template. Consider duplicating this template and naming it appropriately for use with TN5250 (Ex: IBM AS400 TN5250). Add a new field to the template called **Host**


# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `TN5250 Launcher`
1. Enter the **Process Name**: `C:\Program Files (x86)\TN5250\TN5250.exe`
1. Enter the **Process Arguments**: `$Host env.USER=$USername env.IBMSUBSPW=$Password`
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**


# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select TN5250 Launcher for **Launcher Type to use**
1. Set **Domain** to `Host`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
