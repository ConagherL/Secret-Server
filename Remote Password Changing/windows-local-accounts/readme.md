# Introduction

Windows Local Account RPC and HB for environments that do not allow remote access or require special Proxy configurations.

# Permissions

A privileged account that has Administrator privileges on the target endpoint is required.

# Setup

## Create Scripts

Navigate to **Admin | Scripts** and create a script for the HB and RPC using the details below.

### Script - Heartbeat

| Field       | Value                                              |
| ----------- | -------------------------------------------------- |
| Name        | Windows Local Account HB                           |
| Description | Script to heartbeat local user with privileged     |
| Category    | Heartbeat                                          |
| Script      | Paste contents of the heartbeat script in Appendix |

### Script - Password Changer

| Field       | Value                                                     |
| ----------- | --------------------------------------------------------- |
| Name        | Windows Local Account RPC                                 |
| Description | Script for password rotation local user with privileged   |
| Category    | Password Changing                                         |
| Script      | Paste contents of the password changer script in Appendix |

## Create Password Changer

1. Navigate to **Admin | Remote Password Changing**
1. Click **Configure Password Changers**
1. Click **New**
1. Provide following details:

    | Field                 | Value                     |
    | --------------------- | ------------------------- |
    | Base Password Changer | PowerShell Script         |
    | Name                  | Windows Local Account RPC |

1. Click **Save**
1. Click drop-down under _Verify Password Changed Commands_
1. Select **Windows Local Account HB**
1. Enter following for **Script Arguments**: `$MACHINE $USERNAME $PASSWORD "0" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD`
1. Click drop-down under _Password Change Commands_
1. Select **Windows Local Account RPC**
1. Enter following for **Script Arguments**: `$MACHINE $USERNAME $NEWPASSWORD "0" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD`
1. Click **Save**

# Create Windows Local Account Template

> **Note:** Create copy of OOB template if desired.

1. Navigate to **Admin | Secret Templates**
1. Click **Windows Account**
1. Click **Copy Secret Template**
1. Provide a new template name
1. Click **Ok**
1. Click **Configure Password Changing**
1. Click **Edit**
1. Adjust the **Retry Interval** and **Maximum Attempts** to your requirements
1. Adjust the **Heartbeat Check Interval** to your requirements.
1. Click drop-down for **Password Type to use**
1. Select **Windows Local Account HB**
1. Click drop-down for **Domain**
1. Select **Machine**
1. Confirm selections for **Password** and **User Name** are set correctly
1. Select a Secret for **Default Privileged Account**

Proceed to create a new secret and test/verify the HB and RPC function correctly.

# Appendix

## Heartbeat Script

```powershell
<#
    .EXAMPLE
    $MACHINE $USERNAME $PASSWORD "4614" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    Arguments supporting use of proxied port for PowerShell remoting

    .EXAMPLE
    $MACHINE $USERNAME $PASSWORD "0" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    Arguments that will not use proxied port for PowerShell remoting
#>
$machine = $args[0]
$username = $args[1]
$password = $args[2]
$port = $args[3]
$privDomain = $args[4]
$privUsername = $args[5]
$privPassword = ConvertTo-SecureString -String $args[6] -AsPlainText -Force
$privAccount = $privDomain, $privUsername -join '\'

$privCred = [pscredential]::new($privAccount,$privPassword)

$sessionParams = @{
    ComputerName = $machine
    Credential   = $privCred
}
if ($port -gt 0) {
    $sessionOption = New-PSSession -ProxyAccessType NoProxyServer
    $authOption = 'CredSSP'

    $sessionParams.Add('Port',$port)
    $sessionParams.Add('SessionOption',$sessionOption)
    $sessionParams.Add('Authentication',$authOption)
}

try {
    $session = New-PSSession @sessionParams
} catch {
    throw "Unable to remotely connect to [$machine]: $($_)"
}

if ($session) {
    $ScriptBlock = {
        $logonUserSignature =
        @"
[DllImport( "advapi32.dll" )]
public static extern bool LogonUser( String lpszUserName, String lpszDomain, String lpszPassword, int dwLogonType, int dwLogonProvider, ref IntPtr phToken );
"@
        $closeHandleSignature =
        @"
[DllImport( "kernel32.dll", CharSet = CharSet.Auto )]
public static extern bool CloseHandle( IntPtr handle );
"@
        $revertToSelfSignature =
        @"
[DllImport("advapi32.dll", SetLastError = true)]
public static extern bool RevertToSelf();
"@
        $AdvApi32 = Add-Type -MemberDefinition $logonUserSignature -Name "AdvApi32" -Namespace "PsInvoke.NativeMethods" -PassThru
        $Kernel32 = Add-Type -MemberDefinition $closeHandleSignature -Name "Kernel32" -Namespace "PsInvoke.NativeMethods" -PassThru
        $AdvApi32_2 = Add-Type -MemberDefinition $revertToSelfSignature -Name "AdvApi32_2" -Namespace "PsInvoke.NativeMethods" -PassThru
        [Reflection.Assembly]::LoadWithPartialName("System.Security") | Out-Null
        #LogonType  (BATCH = 4, INTERACTIVE = 2, NETWORK = 3, NETWORK_CLEARTEXT = 8, NEW_CREDENTIALS = 9, SERVICE = 5)
        #LogonProviderID (DEFAULT = 0, WINNT40 = 2, WINNT50 = 3)

        $Logon32ProviderDefault = 0
        $Logon32LogonType = 2
        $tokenHandle = [IntPtr]::Zero
        $success = $false
        #Attempt a logon using this credential
        $success = $AdvApi32::LogonUser($using:username, $null, $using:password, $Logon32LogonType, $Logon32ProviderDefault, [Ref] $tokenHandle)
        if (!$success ) {
            $retVal = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            return Write-Error -Message "Wrong user or password" -Category AuthenticationError
        } else {
            $Kernel32::CloseHandle( $tokenHandle ) | Out-Null
            return $True
        }
    }
    Invoke-Command -Session $session -Command $ScriptBlock
} else {
    throw "PSSession object not found"
}
# clear session out, not worried about errors
Get-PSSession -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue
```

## Password Change Script

```powershell
<#
    .EXAMPLE
    $MACHINE $USERNAME $NEWPASSWORD "4641" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    Arguments supporting use of proxied port for PowerShell remoting

    .EXAMPLE
    $MACHINE $USERNAME $NEWPASSWORD "0" $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD

    Arguments that will not use proxied port for PowerShell remoting
#>
$machine = $args[0]
$username = $args[1]
$password = ConvertTo-SecureString -String $args[2] -AsPlainText -Force
$port = $args[3]
$privDomain = $args[4]
$privUsername = $args[5]
$privPassword = ConvertTo-SecureString -String $args[6] -AsPlainText -Force
$privAccount = $privDomain, $privUsername -join '\'

$privCred = [pscredential]::new($privAccount,$privPassword)

$sessionParams = @{
    ComputerName = $machine
    Credential = $privCred
}
if ($port -gt 0) {
    $sessionOption = New-PSSession -ProxyAccessType NoProxyServer
    $authOption = 'CredSSP'

    $sessionParams.Add('Port',$port)
    $sessionParams.Add('SessionOption',$sessionOption)
    $sessionParams.Add('Authentication',$authOption)
}

try {
    $session = New-PSSession @sessionParams
} catch {
    throw "Unable to remotely connect to [$machine]: $($_)"
}

if ($session) {
    $ScriptBlock = {
        $user = $using:username
        try {
            $localUser = Get-LocalUser -Name $user -ErrorAction Stop
        } catch {
            throw "Issue getting User [$user]: $($_)"
        }

        try {
            $localUser | Set-LocalUser -Password $using:password -ErrorAction Stop
        } catch {
            throw "Issue changing password for User [$user]: $($_)"
        }
    }
    Invoke-Command -Session $session -Command $ScriptBlock
} else {
    throw "PSSession object not found"
}
# clear session out, not worried about errors
Get-PSSession -ErrorAction SilentlyContinue | Remove-PSSession -ErrorAction SilentlyContinue
```
