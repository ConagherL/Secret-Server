# Introduction

This document provides the details for creating a custom Launcher for SQL Plus. SQL Plus is an application that is generally used by Oracle DB administrators to connect from their workstations to databases directly and provides a command line interface type access to databases. I added the launcher to the default “Oracle Account” template, which doesn’t have a launcher by default. SQL Plus is generally installed in C:\apps\<username>\ (of the person who installed it) but during installation appears to be added to the PATH which negates the need to reference the full file path directly. 

## Template

Please note that with this launcher we simply leverage default templates. For this launcher, we use the "Oracle Account" template. Consider duplicating these templates and naming them appropriately for use with SQL Plus. 

# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `SQL*Plus`
1. For **Additional Prompt Field Name** enter `Server`
1. Enter the **Process Name**: `sqlplus.exe` 
1. Enter the **Process Arguments**: `$username/$password@$Server:1522/$database`
1. Checkmark **Wrap custom parameters with quotation marks** option
1. Click **Save**


# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select SQL*Plus for **Launcher Type to use**
1. Set **Domain** to `<blank>`
1. Set **Password** to `Password`
1. Set **Server** to `Server`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
