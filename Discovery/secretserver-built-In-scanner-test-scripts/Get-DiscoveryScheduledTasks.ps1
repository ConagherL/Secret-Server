using namespace Microsoft.Win32.TaskScheduler
[Reflection.Assembly]::LoadFile("C:\Program Files\Thycotic Software Ltd\Distributed Engine\Microsoft.Win32.TaskScheduler.dll")

Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain

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



$ConnectionObj = New-Object -TypeName psobject

$ConnectionObj | Add-Member -MemberType noteproperty -Name targetServer -Value $MachineName
$ConnectionObj | Add-Member -MemberType noteproperty -Name userName -Value $user
$ConnectionObj | Add-Member -MemberType noteproperty -Name accountDomain -Value $domain
$ConnectionObj | Add-Member -MemberType noteproperty -Name password -Value $pwd
$ConnectionObj | Add-Member -MemberType noteproperty -Name forceV1 -Value $false

$creds= $ConnectionObj

Write-Host "Server:"$creds.targetServer
Write-Host "User:"$creds.userName
Write-Host "Domain:"$creds.accountDomain

$ts=$null
$ts=[TaskService]::new($creds.targetServer, $creds.userName, $creds.accountDomain, $creds.password, $creds.forceV1)
$tasks=$ts.FindAllTasks(".*")


  $ScheduledTaskAccounts = @()
  foreach($task in $tasks)
  {
      $object = New-Object –TypeName PSObject;
      $object | Add-Member -MemberType NoteProperty -Name Username -Value $username;
      $object | Add-Member -MemberType NoteProperty -Name Machine -Value $creds.targetServer;
      $object | Add-Member -MemberType NoteProperty -Name Domain -Value $domain;
      $object | Add-Member -MemberType NoteProperty -Name TaskName -Value $task.Name;
      $object | Add-Member -MemberType NoteProperty -Name Principal -Value $task.Definition.Principal.UserId;

      $ScheduledTaskAccounts += $object
      $object

      $taskUser = $task.Definition.Principal.UserId;
      if(![string]::IsNullOrEmpty($taskuser) -and ($taskUser.Contains("@") -or $taskUser.Contains("\")))
      {
            write-host "Contains a username. Here is the object info. Now we will make an object"
           $dependency = write-host $object
           
      }
      else
      {
            write-host "Not Empty AND Doesn't contain @ or \ therefore we need to resolve the name"
            
            [xml]$xml=New-Object System.Xml.XmlDocument
            $xml.LoadXml($task.Definition.XmlText);
           
            $sid=$null
            $userids=$xml.GetElementsByTagName("UserId")
            foreach($userid in $userIds)
            {
                
                if(![string]::IsNullOrEmpty($($userid.ParentNode)) -and $userid.ParentNode.Name.ToUpper() -eq "PRINCIPAL")
                {
                    $sid=$userid.InnerText
                }
            }
            

            IF(![string]::IsNullOrEmpty($sid) -and $sid.StartsWith("S-1-5-"))
            {
                write-host "Attempting to resolve the username of the SID in AD."

                $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext $ct,$creds.accountdomain,$creds.username,$creds.password
                
                $UserIdentity = [System.DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($context, $sid)

                
                IF(![string]::IsNullOrEmpty($userIdentity))
                {
                    write-host "Found it: "$useridentity
                }
                else
                {
                    write-host "Nothing found when trying to resolve the SID in AD."
                }

                IF(![string]::IsNullOrEmpty($useridentity))
                {
                    $taskuser=$useridentity.userprincipalname
                }


                IF(![string]::IsNullOrEmpty($taskUser) -and ($taskUser.Contains("@") -or $taskUser.Contains("\")))
                {
                    write-host "Mission accomplished. Dependency will be attepted to be created with this object."
                    write-host "Username: "
                    $taskuser
                    write-host "Task: "
                    $task
                }
            }

       }



      

  }

  $taskstring= $ts.AllTasks | out-string
  out-file -InputObject $taskstring -FilePath "c:\test\test.txt" -Append

}



$MachineName="scorpian"
$Domain="testlab"
$Username="Administrator"
$varstr = read-host -assecurestring -prompt "Enter your password (the input is masked)"
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($varstr)
$password = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($ptr)

Get-DiscoveryRpcAccounts $MachineName $Domain $Username $password

