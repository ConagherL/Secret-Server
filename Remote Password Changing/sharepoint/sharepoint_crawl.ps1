$Server = $args[0]
$UserName = $args[1]
$Domain = $args[2]
$P_Username = $Domain, $UserName -join "\"
$P_Password = ConvertTo-SecureString -String $args[3] -AsPlainText -Force
$managedDomain = $args[4]
$ManagedUserName = $args[5]
$ManagedAccount = $managedDomain, $ManagedUserName -join "\"
$NewPassword = ConvertTo-SecureString -String $args[6] -AsPlainText -Force
$Cred = New-Object -TypeName System.Management.Automation.PSCredential ($P_Username, $P_Password)
$Session = New-PSSession -ComputerName $Server -Authentication CredSSP -Credential $Cred

Invoke-Command -Session $Session -ScriptBlock {
    try {
        Add-PSSnapin Microsoft.SharePoint.PowerShell
        $sa = Get-SPEnterpriseSearchServiceApplication 'Search Service Application'
        Set-SPEnterpriseSearchServiceApplication -Identity $sa -DefaultContentAccessAccountName $using:ManagedAccount -DefaultContentAccessAccountPassword $using:NewPassword
        IISReset
    } catch {
        throw
    }
}
Remove-PSSession -Session $Session
