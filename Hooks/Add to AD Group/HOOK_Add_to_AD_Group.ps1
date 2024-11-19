Import-Module ActiveDirectory
#Get the AD user as an input from Secret Server $args[0]
$ADUser = Get-ADUser -Identity $args[0]
#Get the list of current groups that user is a member of, to ensure they aren't already a member.
$CurrentGroups = Get-ADPrincipalGroupMembership $ADUser | Select Name
#Return the Group Object from AD as an input from Secret Server $args[1]
$GroupToAdd = Get-ADGroup -Identity $args[1]

#If the member is currently not a member of the group, add that user, if they are a member, return.
if(!$currentGroups.Name.Contains($GroupToAdd.Name))
{
    $result = Add-ADPrincipalGroupMembership -Identity $ADUser -MemberOf $GroupToAdd -Confirm:$false
    return $result
}
else
{
    return
}
