# Replace 'OU=YourOU,DC=example,DC=com' with the distinguished name of your OU
$ouDistinguishedName = "OU=YourOU,DC=example,DC=com"

# Get all AD groups in the specified OU
$groups = Get-ADGroup -Filter * -SearchBase $ouDistinguishedName -Properties objectGUID

# Loop through each group and convert objectGUID to hexadecimal string
foreach ($group in $groups) {
    $guid = $group.objectGUID
    $bytes = $guid.ToByteArray()
    $hexGUID = ($bytes | ForEach-Object { $_.ToString("X2") }) -join ''
    Write-Output "Group: $($group.Name), Hexadecimal objectGUID: $hexGUID"
}
