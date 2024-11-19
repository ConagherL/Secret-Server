Import-Module ActiveDirectory
#Get the AD user as an input from Secret Server $args[0]
$ADUser = Get-ADUser -Identity $args[0]
#Get the list of current groups that user is a member of, to ensure they aren't already a member.
$CurrentGroups = Get-ADPrincipalGroupMembership $ADUser | Select Name
#Return the Group Object from AD as an input from Secret Server $args[1]
$GroupToRemove = Get-ADGroup -Identity $args[1]

#If the member is currently a member of the group, remove that user, if they not a a member, return.

if($CurrentGroups.Name.Contains($GroupToRemove.Name))
{
    $result = Remove-ADPrincipalGroupMembership -Identity $ADUser -MemberOf $GroupToRemove -Confirm:$false
    return $result
}
else
{
    return
}
