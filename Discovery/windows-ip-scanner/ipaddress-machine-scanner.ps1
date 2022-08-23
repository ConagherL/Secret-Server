$Ou = $args[0];
$domain = $args[1];
$distinguisheddomain = "DC=" + ($domain.Split('.') -join ",DC=");
if ($distinguisheddomain.ToLower() -eq $Ou.ToLower())
{
$searchbase = $distinguisheddomain
}
else
{
$searchbase = "CN=$Ou,$distinguisheddomain"
}
$FoundComputers = @()
$ComputersinOU = Get-ADComputer -Filter 'Name -like "*"' -Server $domain -SearchBase $searchbase -properties *
foreach ($comp in $ComputersinOU)
{
                    
  $object = New-Object –TypeName PSObject;
  $object | Add-Member -MemberType NoteProperty -Name ComputerName -Value $Comp.Name;
  $object | Add-Member -MemberType NoteProperty -Name DNSHostName -Value $comp.DNSHostName;
  $object | Add-Member -MemberType NoteProperty -Name ADGUID -Value $comp.ObjectGuid;
  $object | Add-Member -MemberType NoteProperty -Name OperatingSystem -Value $comp.OperatingSystem;
  $object | Add-Member -MemberType NoteProperty -Name DistinguishedName -Value $comp.DistinguishedName.Replace(",$distinguisheddomain", '');
 
  $FoundComputers +=$object;
 
}
return $FoundComputers
# args: $target $[1]$domain