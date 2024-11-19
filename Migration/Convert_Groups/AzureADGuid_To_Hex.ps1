# Connect to Azure AD
Connect-AzureAD

# Get all groups
$groups = Get-AzureADGroup

# Loop through each group, convert ObjectId to hexadecimal
foreach ($group in $groups) {
    $guid = $group.ObjectId
    $bytes = [System.Guid]::Parse($guid).ToByteArray()
    $hex = ($bytes | ForEach-Object { $_.ToString("X2") }) -join ''
    Write-Output "Group: $($group.DisplayName), Hexadecimal ObjectId: $hex"
}
