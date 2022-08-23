
Function Invoke-AccountDiscovery {
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True)]
    [String] $Target,
    [Parameter(Mandatory=$True)]
    [String] $Username,
    [Parameter(Mandatory=$True)]
    [String] $Password
)

    import-module posh-ssh
    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Creds = New-Object -TypeName System.Management.Automation.PSCredential ($Username, $SecurePassword)
    try{
        $session = New-SSHSession -ComputerName $Target -Credential $Creds -ConnectionTimeout 99999 -AcceptKey -Force
        $SSHStream = New-SSHShellStream -SSHSession $session
        Start-Sleep -Seconds 5
        $SSHStream.WriteLine("get system admin | grep name")
        Start-Sleep -Seconds 2
        $Output = $SSHStream.Read()
        $SSHStream.WriteLine("exit")
        $SSHStream.Close()
        $accounts = @()
        $result = $Output -split "`n" | Select-String "name:" -AllMatches
        foreach($line in $result){
            $account = "" | Select-Object Machine, UserName
            $account.username = $($line -split ": ")[1];
            $account.Machine = $Target;
            $accounts +=$account
}
       
        if($accounts.count -ne 0){
            return $accounts
        }
        else {
            throw "No Accounts Found"
        }
    }
    catch{
            Throw "Invalid Password, please ensure the password is correct." + $_
    }
 


}

Invoke-AccountDiscovery -Target $args[0] -Username $args[1] -Password $args[2]



