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