<# Utilize the Run As secret #>
$params = $args
$Target = $params[0]
$ServiceName = $params[1]
$ServicePwd = ConvertTo-SecureString -String $params[2] -AsPlainText -Force

$serviceCred = [pscredential]::new('Ignore this value',$ServicePwd)
Invoke-Command -ComputerName $Target -ScriptBlock {
    [pscredential]$cred = $using:serviceCred
    [System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')> $null
    $sqlwmiLocal = New-Object 'Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer'

    $targetService = $sqlwmiLocal.Services | Where-Object Name -EQ $using:ServiceName
    if ($targetService) {
        try {
            $targetService.ChangePassword('ignore this value',$cred.GetNetworkCredential().Password)
            $targetService.Alter()
        } catch {
            throw "Error updating the service password on $($using:Target) for service $($targetService.Name): $($_.Exception)"
        }
    } else {
        throw "Service $($using:ServiceName) not found on $($using:Target)."
    }
}
