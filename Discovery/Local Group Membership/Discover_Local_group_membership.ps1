# Expected Arguments 


$params = $args

$Target = $args[0]

$PrivUser = "$($params[1])\$($params[2])"

$PrivPwd = ConvertTo-SecureString -String $params[3] -AsPlainText -Force

$cred = [pscredential]::new($PrivUser,$PrivPwd)

$Groups =  @('Administrators','Remote Desktop Users','Power Users')

$results = @()

try {

    Invoke-Command -ComputerName $Target -Credential $cred -HideComputerName -ScriptBlock {

        foreach($group in $Groups)

        {

        foreach($member in Get-LocalGroupMember -Name $group) {

            [pscustomobject]@{

                Machine     = $env:COMPUTERNAME

                Group       = $group

                Member      = $member.Name

            }

        }

            $results += $output

        }

        return $results

        

    }

} catch {

    throw "Unable to connect to target: $($args[0]) `n$_"

}