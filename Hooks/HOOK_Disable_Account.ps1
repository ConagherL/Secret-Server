$GetUserStatus = Get-ADUser -Identity $Args[0]
if ($GetUserStatus.Enabled -eq $true){
    $GetUserStatus | Set-ADUser -Enabled $false}

Else {
    return
    }