Function Get-LocalWmiAppPools{

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

    $domuser="$Domain\$User"

    $namespace = "root\MicrosoftIISv2"
    $Class = "IIsApplicationPoolSetting"
    #$filter = "Name='W3SVC/APPPOOLS/DefaultAppPool'"

    $timeout=5
    [string[]] $wmiProps = "name", "WamUserName"

    $remote = $MachineName -notmatch $Env:COMPUTERNAME

        $ConnectionOptions = new-object System.Management.ConnectionOptions
            if ($remote) 
            {
            $ConnectionOptions.Username = $domuser
            $ConnectionOptions.Password = $Pwd
            }
    	    $ConnectionOptions.Impersonation = "Impersonate"
            $ConnectionOptions.Authentication = "PacketPrivacy"
            $ConnectionOptions.EnablePrivileges = $TRUE
        #$connectionoptions

        $EnumerationOptions = new-object System.Management.EnumerationOptions 
    
        $timeoutseconds = new-timespan -seconds $timeout
        $EnumerationOptions.set_timeout($timeoutseconds) 
    
        $assembledpath = "\\" + $MachineName + "\" + $namespace

        
        $path = new-object System.Management.ManagementPath $assembledpath
        $Scope = new-object System.Management.ManagementScope $path, $ConnectionOptions
        $Scope.Connect() 
    
        if (!$remote) 
            {
            Write-Host ("Local machine WMI running as user: {0}" -f [System.Security.Principal.WindowsIdentity]::GetCurrent().Name) -ForegroundColor Magenta
            }


        try {    
            $wmiQuery = new-object -TypeName System.Management.SelectQuery -ArgumentList "IIsApplicationPoolSetting", $null, $wmiProps   

            $searcher = new-object System.Management.ManagementObjectSearcher
            $searcher.set_options($EnumerationOptions)
            $searcher.Query = $wmiQuery
            $searcher.Scope = $Scope 
            #return $searcher.get() 

                if ($searcher.Get().Count -ne 0)
                { 
                #write-host $searcher.get()
                        foreach ($managementObject in $searcher.Get())
                        { 
                        $wam = $managementObject["WAMUsername"].ToString()
                        $AppPoolPath = $managementObject["name"].ToString()
                        if($wam)
                            {
                            Write-Log ("IIS6 Compatible App Pool: {0} started with account {1}" -f $AppPoolPath, $wam)
                            }
                        }
                }                 
                else 
                {
                    Write-Host "No App Pools identified" -ForegroundColor Yellow
                    Write-Log "No App Pools identified"
                }
           }
        catch [exception] 
            {
            Write-Host ("Unexpected exception occurred: {0}" -f $_.Exception)
            }
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

Get-LocalWmiAppPools $machine $domain $username $pwd
