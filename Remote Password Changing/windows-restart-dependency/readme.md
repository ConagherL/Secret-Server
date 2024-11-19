# Introduction

This documents provides the details for configuring a dependency changer to force a windows computer to restart.

# Windows Computer Restart

The script takes a single parameter of the server hostname and will attempt to gracefully restart the server.

# Create Script

1. Navigate to **Admin | Scripts**
2. Enter name: **Windows Computer Restart**
3. Description: **Script for forcing a computer restart**
4. Category: **Dependency**
5. Script: **Copy and Paste** the provided script [restart-windows.ps1](restart-windows.ps1)
6. Click **OK**

# Create Dependency

1. Navigate to your desired secret
2. Navigate to **Dependencies** tab
3. Create a **New Dependency** (_create a dependency group if one does not currently exist_)
4. Click the drop down for **Type**
5. Select the **Windows Computer Restart** under the **Run PowerShell Script** section
6. Provide a **Dependency Name**
7. Select a **Run As** secret if required according to your Secret Server configuration
8. Enter **5** for **Wait(s)**
9. Arguments enter `$MACHINE`
10. Click **Save**
