# Introduction

This document provides the details for creating a custom Launcher for Chrome. Several different types of launchers can be found below for various use cases

## Template

Please note that with this launcher we simply leverage default templates. We use the default "Web Password" template. Consider duplicating this template and naming it appropriately for use with Chrome (Ex: Chrome Template). The name of this template may vary based on which launcher you decide to use below. 

# Create Launcher (Chrome Incognito)

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `Chrome Incognito`
1. Enter the **Process Name**: `C:\Program Files (x86)\Google\Chrome\Application\chrome.exe`
1. Enter the **Process Arguments**: `-incognito $URL`
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**

## Configure Template Launcher (Chrome Incognito)

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select Chrome Incognito for **Launcher Type to use**
1. Set **Domain** to `Blank`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Set **URL** to `URL`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.

# Create Launcher (Chrome Launch As User)

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `Chrome Launch As User`
1. For **Additional Prompt Field Name** put: URL
1. Enter the **Process Name**: `C:\Program Files (x86)\Google\Chrome\Application\chrome.exe`
1. Enter the **Process Arguments**: `$URL`
1. Checkmark **Wrap custom parameters with quotation marks** option
1. Checkmark **Run Process As Secret Credentials** option
1. Checkmark **Load User Profile** option
1. Click **Save**

## Configure Template Launcher (Chrome Launch As User)

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select Chrome Launch As User for **Launcher Type to use**
1. Set **Domain** to `Domain`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Set **URL** to `<user input>`
1. Click **Save**

If you decide to use the out of box Launcher Type of Website Login instead of the custom launcher you created then specify:

1. Set **Password** to `Password`
1. Set **URL** to `URL`
1. Set **Username** to `Username`

Create a secret and test/verify the launcher functions properly.

## Create Launcher (Chrome Multiple URLs)

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `Chrome Multiple URLs`
1. For **Additional Prompt Field Name** put: URL
1. Enter the **Process Name**: `C:\Program Files (x86)\Google\Chrome\Application\chrome.exe`
1. Enter the **Process Arguments**: `$URL`
1. Checkmark **Wrap custom parameters with quotation marks** option
1. Click **Save**

## Configure Template Launcher (Chrome Multiple URLs)

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select Chrome Multiple URLs for **Launcher Type to use**
1. Set **Domain** to `URL`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Set **URL** to `<user input>`

1. Under the Advanced Settings checkmark **Restrict User Input**
1. For the **Restrict As** setting, choose **Whitelist**
1. For the Restrict By Secret Field, choose **URL**
1. Leave INclude Machines From Dependencies unchecked
1. Click **Save**

This process will attach Chrome launcher to web password template. When you click on launcher, it will let you pick the URL you would like to open. 

The URL field in an example secret should be populated as below to work correctly:

``
https://website.com,https://website2.com
``

Create a secret and test/verify the launcher functions properly.
