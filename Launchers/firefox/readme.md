# Introduction

This document provides the details for creating a custom Launcher to launch FireFox in private mode.

## Template

Please note that with this launcher we simply leverage default templates. We use the default "Web Password" template. Consider duplicating this template and naming it appropriately for use with Firefox (Ex: Firefox Template). The name of this template may vary based on which launcher you decide to use below. 

# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `Launch FireFox in Private Mode`
1. For **Additional Prompt Field Name** enter: `URL`
1. Enter the **Process Name**: `C:\Program Files\Mozilla Firefox\firefox.exe`
1. Enter the **Process Arguments**: `-private-window $URL`
1. Checkmark **Wrap custom parameters with quotation marks** option
1. Click **Save**

# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select LDP Launcher for **Launcher Type to use**
1. Set **Domain** to `<blank>`
1. Set **Password** to `Password`
1. Set **URL** to `URL`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
