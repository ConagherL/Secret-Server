Function Get-DiscoveryMwaAppPools{

    [cmdletbinding()]

    param (
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$MachineName,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Domain,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$User,

		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string]$Pwd
    )


[Void][Reflection.Assembly]::LoadWithPartialName("Microsoft.Web.Administration")

$logonUserSignature =
@'
[DllImport( "advapi32.dll" )]
    public static extern bool LogonUser( 
        String lpszUserName,
        String lpszDomain,
        String lpszPassword,
        int dwLogonType,
        int dwLogonProvider,
        ref IntPtr phToken 
    );
'@


$AdvApi32 = Add-Type -MemberDefinition $logonUserSignature -Name "AdvApi32" -Namespace "PsInvoke.NativeMethods" -PassThru

$closeHandleSignature = @'
    [DllImport( "kernel32.dll", CharSet = CharSet.Auto )]
    public static extern bool CloseHandle( IntPtr handle );
'@

$Kernel32 = Add-Type -MemberDefinition $closeHandleSignature -Name "Kernel32" -Namespace "PsInvoke.NativeMethods" -PassThru

    $domuser="$Domain\$User"
    $pass = ConvertTo-SecureString -AsPlainText $Pwd -Force

    $SecureString = $pass
    # Users you password securly
    $credentialss = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $domuser,$SecureString

    $mwacheck = $null

   try
   {
        $Logon32ProviderDefault = 0
        $Logon32LogonInteractive = 2
        $tokenHandle = [IntPtr]::Zero
        $AppUserName = Split-Path $credentialss.UserName -Leaf
        $dom = Split-Path $credentialss.UserName
        $unmanagedString = [IntPtr]::Zero;
        $success = $false
    
        try
        {
            $unmanagedString = [System.Runtime.InteropServices.Marshal]::SecureStringToGlobalAllocUnicode($credentialss.Password);
            $success = $AdvApi32::LogonUser($AppUserName, $dom, [System.Runtime.InteropServices.Marshal]::PtrToStringUni($unmanagedString), $Logon32LogonInteractive, $Logon32ProviderDefault, [Ref] $tokenHandle)
        }
        finally
        {
            [System.Runtime.InteropServices.Marshal]::ZeroFreeGlobalAllocUnicode($unmanagedString);
        }
    
        if (!$success )
        {
            $retVal = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
            Write-Log "LogonUser was unsuccessful. Error code: $retVal"
            return
        }

        Write-Log "LogonUser was successful."
        Write-Log "Value of Windows NT token: $tokenHandle"
        
        $identityName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Write-Log "Current Identity: $identityName"

        $newIdentity = New-Object System.Security.Principal.WindowsIdentity( $tokenHandle )
        $context = $newIdentity.Impersonate()

        $identityName = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        Write-Log "Impersonating: $identityName"


        try
        {
            $serverManager = [Microsoft.Web.Administration.ServerManager]::OpenRemote($Machine)
           

            $AppPools = $serverManager.ApplicationPools
                       
            if ($AppPools)
            { 
            Write-Log "*** Application Pools Identified ***" 
                foreach($pool in $AppPools)
                {
                #$pool
                $pname = $pool.name
                $pauto = $pool.Autostart
                $pstate = if ($pool.State){$pool.State} else {"Not Started"}
                $puser = if($pool.processModel.Username){$pool.processModel.Username} else {"User Identity Not Used"}

                Write-Log "---------------"
                Write-Log "Name: $pname"
                Write-Log "State: $pstate"
                Write-Log "Autostart: $pauto" 
                Write-Log "Identity User: $puser"
               # Write-Log "---------------"
                }
                $mwacheck=1
            }
            else
            {
                Write-Host "No Application Pools Found in" $Computername -ForegroundColor Yellow
                Write-Log "No Application Pools Found in $Computername" 
            }

            $serverManager.Dispose()
        }
        catch
        {
            Write-Log $_.Exception.ToString() 
            $mwacheck = $_.Exception.ToString()       
        }
 
    }
    catch [System.Exception]
    {
        Write-Log $_.Exception.ToString() -Level Error
        #$mwacheck = $_.Exception.ToString()
        Write-Error -Message:"An Error Has Occurred" -Category:NotSpecified -ErrorAction:SilentlyContinue
        $PSCmdlet.WriteError($_)
        return
    }
    finally
    {
        if ( $context -ne $null )
        {
            $context.Undo()
        }
        if ( $tokenHandle -ne [System.IntPtr]::Zero )
        {
            $Kernel32::CloseHandle( $tokenHandle ) | Out-Null
        } 
    } 
    #write-host "Error: "$mwacheck
    
} 

function Write-Log 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("LogContent")]
        [string]$Message, 

       [Parameter(Mandatory=$false)]
        [Alias('LogPath')]
        [string]$Path=[io.path]::combine($scriptRootFolder, "c:\Logs\$($startTime)\$($computername).log"),
         
		[Parameter(Mandatory=$false)]
		[ValidateSet("Error","Warn","Info")]
		[string]$Level="Info"
    ) 

   Begin
    {
        # Set VerbosePreference to Continue so that verbose messages are displayed.
        $VerbosePreference = 'Continue'
    }
    Process
    {
        
		# If attempting to write to a log file in a folder/path that doesn't exist create the file including the path.
		if (!(Test-Path $Path)) {
			Write-Verbose "Creating $Path."
			$NewLogFile = New-Item $Path -Force -ItemType File
		}


       # Format Date for our Log File
        $FormattedDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

		# Write message to error, warning, or verbose pipeline and specify $LevelText
		switch ($Level) {
			'Error' {
				Write-Error $Message
				$LevelText = 'ERROR:'
				}
			'Warn' {
				Write-Warning $Message
				$LevelText = 'WARNING:'
				}
			'Info' {
				Write-Verbose $Message
				$LevelText = 'INFO:'
				}
			}
		
		# Write log entry to $Path
		"$FormattedDate $LevelText $Message" | Out-File -FilePath $Path -Append
    }
    End
    {
    } 
}

$machine="scorpian"
$domain="testlab"
$username="Administrator"
$varstr = read-host -assecurestring -prompt "Enter your password (the input is masked)"
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($varstr)
$pwd = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr)

Get-DiscoveryMwaAppPools $machine $domain $username $pwd