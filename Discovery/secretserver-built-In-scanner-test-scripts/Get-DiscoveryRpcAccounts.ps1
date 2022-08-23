Function Get-DiscoveryRpcAccounts {

    [cmdletbinding()]

    param(
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
    
    $objComputer = New-Object System.DirectoryServices.DirectoryEntry("WinNT://$MachineName", "$Domain\$User" , $Pwd)

    $children = $objComputer.Children | where {$_.SchemaClassName -match "user"}

    $ADS_UF_ACCOUNTDISABLE = 0x00002
    
    foreach ($lu in $children | Select-Object @{name="User";Expression={$_.psbase.properties.name.value}},
           # @{Name="Description";Expression={$_.psbase.properties.description.value}},
            @{name="Disabled";Expression={
                if ($_.psbase.properties.item("userflags").value -band $ADS_UF_ACCOUNTDISABLE) {
                    $true
                     }
                     else {
                    $false
                     }
                    }
            })
            {

           $object = New-Object –TypeName PSObject;
           $object | Add-Member -MemberType NoteProperty -Name Username -Value $lu.User;
          # $object | Add-Member -MemberType NoteProperty -Name Description -Value $lu.Description;
           $object | Add-Member -MemberType NoteProperty -Name Disabled -Value $lu.Disabled;

           $la = $object.Username
           $Disabled = $object.Disabled

        #write-host "Local Account: "$object.Username `t "Disabled?:  "$object.Disabled  -ForegroundColor Magenta
        write-log "Local Account: $la  Disabled?: $Disabled" 
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

$machinename="scorpian"
$domain="testlab"
$username="Administrator"
$varstr = read-host -assecurestring -prompt "Enter your password (the input is masked)"
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($varstr)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr)

Get-DiscoveryRpcAccounts $machinename $domain $username $password