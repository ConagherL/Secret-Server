$GetUserStatus = Get-ADUser -Identity $args[0]
if ($GetUserStatus.Enabled -eq $false){
    Set-ADUser -Identity $Args[0] -Enabled $true}

Else {
    return
    }