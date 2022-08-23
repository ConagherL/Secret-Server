# Introduction

If you have business reasons for exposing the password in Secret Server but would still like to ensure through group policy that users cannot reuse credentials on another system by utilizing RDP Restricted Admin Mode, you can follow the steps below. Please note that this method which utilizes RDP Restricted Admin mode is less secure as is with any custom launcher that may be passing through a $password variable, as the password can be exposed via Process Monitor or other tools. Please only consider using this method in situations where you would like to use RDP Restricted Admin mode in the enterprise, are accessing Secret Server web UI from a locked down jump host only, and have the credentials configured for password changing after each use. Since passwords albeit one-time-use can be exposed via process monitor using this method, lateral or non-lateral movement may be possible for an attacker if they get access to the jump system.

## Steps Required For Launcher To Function

On the destination system enable Restricted Admin in the registry or via GPO. The registry key is in:

HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa

- HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Lsa
- Name: DisableRestrictedAdmin
- Type: REG_DWORD
- Value: 0

You may also need to verify that restricted remote administration has been enabled as well:

HKLM\Software\Policies\Microsoft\Windows\CredentialsDelegation
Name: RestrictedRemoteAdministration
Type: REG_DWORD
Value: 1

## Template

The built-in template that is named "Windows Account" can be leveraged for this launcher. We recommend copying this template and then renaming it appropriately to something like "Windows Account - RestrictedAdmin"


# Create Launcher

1. Navigate to **Admin | Secret Templates**
1. Click **Configure Launchers** button
1. Click **New**
1. Enter a **Launcher Name** ex: `RDP RestrictedAdmin`
1. Enter the **Process Name**: `powershell`
1. Enter the **Process Arguments**: `cmdkey /generic:"$domain" /user:"$username" /pass:"$password"; Start-Process -FilePath "C:\Windows\System32\mstsc.exe" -ArgumentList "/v:$domain"; Start-Sleep -s 30; cmdkey /delete:$domain"`
1. Uncheck **Wrap custom parameters with quotation marks** option
1. Click **Save**

a)	This creates credentials using values stored on the Secret itself into variables that can be used for running PowerShell. The first command creates credentials in Windows Credential Manager

b)	The second command launches RDP, utilizes the entry for the system, and passes through the credentials stored in Windows Credential Manager. 

c)	The next command puts PowerShell to sleep for 30 seconds, allowing you that time to accept the RDP connection.

d)	The last command deletes the credentials from Windows Credential manager



# Configure Template Launcher

1. Navigate to **Admin | Secret Templates**
1. Select your template
1. Click **Edit**
1. Click **Configure Launcher**. If there is an existing launcher associated to the template, remove it
1. Click **Add New Launcher**
1. Select LDP Launcher for **Launcher Type to use**
1. Set **Domain** to `Machine`
1. Set **Password** to `Password`
1. Set **Username** to `Username`
1. Click **Save**

Create a secret and test/verify the launcher functions properly. Since restrictedAdmin mode requires Administrator rights on the system, it made sense to associate this launcher with the Windows Account template launcher. It may be possible to leverage this launcher with the Active Directory with minor modifications as well.