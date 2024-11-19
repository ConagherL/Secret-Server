Check for inheritenance.

Get-ADUser -SearchBase "DC=myDomain,DC=com" -Filter * | ?{ (Get-Acl $_.DistinguishedName).AreAccessRulesProtected -eq "True" } | ft SamAccountName,Name -AutoSize
