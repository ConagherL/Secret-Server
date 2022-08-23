$params = $args
$privUser = $params[0]
$privPwd = (ConvertTo-SecureString -String $params[1] -AsPlainText -Force)
$veeamServer = $params[2]
$domain = $params[3].Split('.')[0]
$username = $params[4]
$newPassword = $params[5]
$includeNonDomain = $params[6] #Notes field being used

# $privCred = [PSCredential]::new($privUser,$privPwd)
$privCred = New-Object -TypeName PSCredential -ArgumentList $privUser, $privPwd

Invoke-Command -ComputerName $veeamServer -Credential $privCred -ScriptBlock {
    $veeamCred = $null
    # Adjust this string to desired value for switching
    if ($using:includeNonDomain -eq "win+unix") {
        $veeamCred = "$($using:domain)\$($using:username)", $using:username
    } else {
        $veeamCred = "$($using:domain)\$($using:username)"
    }
    try {
        Add-PSSnapin veeampssnapin
    } catch {
        throw "Issue loading snapin: $($_.Exception.Message)"
    }

    foreach ($cred in $veeamCred) {
        $acct = Get-VBRCredentials -Name $cred
        if ($acct.Count -gt 0) {
            Start-Sleep -Seconds 2
            Set-VBRCredentials -Credential $acct -Password $using:newPassword
            $newAcct = Get-VBRCredentials -Name $acct
            if ($newAcct.ChangeTimeLocal -gt $acct.ChangeTimeLocal) {
                $true
            } else {
                throw "Password not properly update for $account"
            }
        }

        if ($acct.Count -lt 0 -or (-not $acct)) {
            throw "Issue getting $cred from Veeam Server"
        }
    }
}