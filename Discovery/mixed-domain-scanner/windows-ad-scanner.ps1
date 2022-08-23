<# Windows Machines w-No Linux scanner- Filters out Non-Windows devices #>

$Ou = $args[0];
$domain = $args[1]
$username = $args[2]
$password = $args[3]
#add-content -path "c:\temp\outfile.txt" -value $Ou
$distinguisheddomain = "DC=" + ($domain.Split('.') -join ",DC=");
if ($distinguisheddomain.ToLower() -eq $Ou.ToLower()) {
    $searchbase = $distinguisheddomain
} else {
    $searchbase = "$Ou,$distinguisheddomain"
}
$Spassword = ConvertTo-SecureString "$password" -AsPlainText -Force #Secure PW
$cred = New-Object System.Management.Automation.PSCredential ("$domain\$username", $Spassword) #Set credentials for PSCredential logon
#add-content -path "c:\temp\outfile.txt" -value  $searchbase
$FoundComputers = @()
#add-content -path "c:\temp\outfile.txt" -value  $FoundComputers
$ComputersinOU = Get-ADComputer -Filter 'Name -like "*"' -Server $domain -SearchBase $searchbase -Credential $cred -properties *
foreach ($comp in $ComputersinOU) {
    if ($null -eq $comp.OperatingSystem) {
        $Os = "Not in AD"
    } else {
        $Os = $comp.OperatingSystem
    }
    $Os = $Os.ToLower()
    if ($Os.IndexOf("windows") -gt -1) {
        $object = [pscustomobject]@{
            ComputerName = $comp.Name
            DNSHostName = $comp.DNSHostName
            ADGUID = $com.ObjectGuid
            OperatingSystem = $Os
            DistinguishedName = $comp.DistinguishedName.Replace(",$distinguisheddomain",'')
        }
        $FoundComputers += $object
    }
}
return $FoundComputers
# args: $target $[1]$domain
