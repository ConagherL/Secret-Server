<# Validate Module is available #>
try {
    Import-Module Posh-SSH -ErrorAction Stop
} catch {
    throw "Issue importing PowerShell module Posh-SSH: $($_.Exception)"
}
function Invoke-PasswordChange {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory)]
        [string]
        $Target,

        [Parameter(Mandatory)]
        [string]
        $Username,

        [Parameter(Mandatory)]
        [string]
        $Password,

        [Parameter(Mandatory)]
        [string]
        $NewPassword
    )

    $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
    $Cred = New-Object -TypeName System.Management.Automation.PSCredential ($Username, $SecurePassword)
    try{
        $session = New-SSHSession -ComputerName $Target -Credential $Cred -ConnectionTimeout 99999 -AcceptKey -Force
        $SSHStream = New-SSHShellStream -SSHSession $session

        #Password changing commands go in this section
        Start-Sleep -Seconds 5
        $SSHStream.WriteLine("passwd")
        Start-Sleep -Seconds 5
        $SSHStream.WriteLine("$NewPassword")
        Start-Sleep -Seconds 5
        $SSHStream.WriteLine("$NewPassword")
        Start-Sleep -Seconds 5
        $SSHStream.WriteLine("exit")

        #Close out session
        $SSHStream.Close()
    } catch{
        Throw "Error updating password - $($_.Exception)"
    }
}

Invoke-PasswordChange -Target $args[0] -Username $args[1] -Password $args[2] -NewPassword $args[3]