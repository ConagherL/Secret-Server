# Introduction

This document provides the details for creating a custom Launcher for IBM iAccess ACS. 

## Template

Please note that with this launcher we simply leverage default templates. We use the default "Windows Account" template. Consider duplicating this template and naming it appropriately for use with ACS (Ex: ACS Template). Add a new field to the template called **SystemName**


# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Choose the **Launcher Type** of Batch File
1. Create a batch file that contains the following commands and then upload it to the **Batch File** section under windows settings. Some lines below may need altered depending on where your acsbundle.jar is located.
```
@echo off
echo launching IBM ACS
java -Xmx1024m -jar <loc>IBMiAccess_v1r1\acsbundle.jar /PLUGIN=CFG /SYSTEM=%1 /IPADDR=%4 /USERID=%2 /R
java -Xmx1024m -jar <loc>IBMiAccess_v1r1\acsbundle.jar /PLUGIN=logon /SYSTEM=%1 /USERID=%2 /PASSWORD=%3
java -Xmx1024m -jar <loc>IBMiAccess_v1r1\acsbundle.jar /PLUGIN=5250 /SYSTEM=%1 /sso=1

```

1. Enter a **Launcher Name** ex: `ACS Launcher`
1. Enter the **Process Arguments**: `$SystemName $USERNAME $PASSWORD $MACHINE"`
1. Checkmark **Use Operating System Shell** option
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**


# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select ACS Launcher for **Launcher Type to use**
1. Set **Domain** to `Machine`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
