
Function Invoke-PasswordChange {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [String] $Target,
    [Parameter(Mandatory=$True)]
    [String] $Username,
    [Parameter(Mandatory=$True)]
    [String] $Password,
    [Parameter(Mandatory=$True)]
    [String] $NewPassword
)

    import-module posh-ssh
    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Creds = New-Object -TypeName System.Management.Automation.PSCredential ($Username, $SecurePassword)
    try{
        $session = New-SSHSession -ComputerName $Target -Credential $Creds -ConnectionTimeout 99999 -AcceptKey -Force
        $SSHStream = New-SSHShellStream -SSHSession $session
        Start-Sleep -Seconds 5
        $SSHStream.WriteLine("passwd")
        Start-Sleep -Seconds 5
        $SSHStream.WriteLine("$NewPassword")
        Start-Sleep -Seconds 5
        $SSHStream.WriteLine("$NewPassword")
        Start-Sleep -Seconds 5
        $Output = $SSHStream.Read()
        $SSHStream.WriteLine("exit")
        $SSHStream.Close()
        $success = Select-String -InputObject $output -Pattern 'Success' -AllMatches
        if($Success.matches.count -ge 1){
            return $true
        }
        else {
            throw "Password Change Error, command output:" + $Output
        }
    }
    catch{
            Throw "Invalid Password, please ensure the password is correct."
    }
 


}

Invoke-PasswordChange -Target $args[0] -Username $args[1] -Password $args[2] -NewPassword $args[3]
