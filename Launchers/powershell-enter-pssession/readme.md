# Introduction

This document provides the details for creating a custom Launcher for PowerShell.  This Launcher requires the process to be run as the Secret Credentials, thus requiring a Windows or Active Directory Secret type.  The HOSTNAME value must also be a DNS name (FQDN or NETBIOS) and not an IP address.

## Template

The secret template for PowerShell can be found here to import:

# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `Powershell - Enter-PSSession`
1. Check **Active**
1. Check **Use Additional Prompt**
1. Enter a **Additional Prompt Field Name**: `HOSTNAME`
1. Uncheck **Use Custom Image?** 'Optional'
1. Uncheck **Wrap custom parameters with quotation marks**
1. Uncheck **Record Multiple Windows**
1. Enter the **Process Name**: `powershell.exe`
1. Enter the **Process Arguments**: `-NoExit -Command "Enter-PSSession -ComputerName "$HOSTNAME""`
1. Check **Run Process As Secret Credentials**
1. Check **Load User Profile**
1. Uncheck **Use Operating System Shell**
1. Click **Save**

# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select Powershell - Enter-PSSession Launcher for **Launcher Type to use**
1. Set **Domain** to `Domain`
1. Set **HOSTNAME** to `<user input>`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly.
