# Introduction

The below contains launchers that can be used for Azure and Microsoft 365 PowerShell modules. Each one can be used to call the desired PowerShell module (e.g., AzureAd) and will provide a credential to the associated "connect" command.

One important note is when using PowerShell process, ensure you are using double-quotes for the command and not curly-braces. The latter will cause the command to output in the console and expose the username and password data.

## Templates

The below can be used with the `Office 365 Account` template for the most part. A few services with Microsoft 365 do require providing a URL (e.g., SharePoint PnP) for the connection. The ones that need the URL you can create a copied template and add the field.

## Launchers

### Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `Powershell - <Module Name>`
1. Check **Active**
1. Uncheck **Record Multiple Windows**
1. Enter the **Process Name**: `powershell.exe`
1. Enter the **Process Arguments**: _use the one associated to the module being configured below_
1. Click **Save**

### Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select `Office 365 Template`, or the custom template desired
1. Click **Edit**
1. Click **Configure Launcher**.
1. Click **Add New Launcher**
1. Select the Launcher created in the previous step
1. Set **Domain** to `Domain`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

## Process Arguments

### AzureAD

```powershell
-NoExit -Command "Import-Module AzureAd; Connect-AzureAd -Credential ([pscredential]::new('$USERNAME@$DOMAIN',(ConvertTo-SecureString -String '$PASSWORD' -AsPlainText -Force)));Clear-Host;Clear-History;"
```
