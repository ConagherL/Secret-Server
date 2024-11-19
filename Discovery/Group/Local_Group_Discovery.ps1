#Authentication Variables
$params = $args
$Target = $args[0]
$PrivUser = "$($params[1])\$($params[2])"
$PrivPwd = ConvertTo-SecureString -String $params[3] -AsPlainText -Force
$cred = [pscredential]::new($PrivUser,$PrivPwd)

# The groups specified assumes these exist on each machine
$Groups =  @('Administrators','Remote Desktop Users','Power Users')


try {
    Invoke-Command -ComputerName $Target -Credential $cred -HideComputerName -ScriptBlock {

    $results = New-Object System.Collections.ArrayList

foreach ($group in $using:Groups) 
{ 
               $groupobject = [ADSI]("WinNT://{0}/{1}" -f $env:COMPUTERNAME, $group)
               $group_members = @($groupobject.Invoke('Members') | % {(([adsi]$_).path -split "WinNT://")[1]})
               
               if ($group_members.Count -gt 1)
               {
                              foreach ($member in $group_members)
                              {
                                             if ($member -like '*NT AUTHORITY*') { continue }
                                             if ($member -match '^.*/.*/.*$') {$member = ($member -split '/')[2]}

                                             $output = New-Object PSObject -Property @{
                                                            Machine = $env:COMPUTERNAME
                                                            Group   = $group
                                                            Username  = $member -replace '/','\'
                                             }

                                             $results.Add($output) | Out-Null
                              }
               }
}
return $results
    }

} catch {
    throw "Unable to connect to target: $($args[0]) `n$_"
}
