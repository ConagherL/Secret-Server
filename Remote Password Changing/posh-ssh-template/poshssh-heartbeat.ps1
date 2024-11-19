<# Validate Module is available #>
try {
    Import-Module Posh-SSH -ErrorAction Stop
} catch {
    throw "Issue importing PowerShell module Posh-SSH: $($_.Exception)"
}
function Invoke-HeartBeat {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingPlainTextForPassword', '')]
    [CmdletBinding()]
    Param(
        [parameter(Mandatory)]
        [string]
        $Target,

        [parameter(Mandatory)]
        [string]
        $Username,

        [parameter(Mandatory)]
        [string]
        $Password
    )
    try{
        $SecurePassword = ConvertTo-SecureString -String $Password -AsPlainText -Force
        $Cred = New-Object -TypeName System.Management.Automation.PSCredential ($Username, $SecurePassword)
        $session = New-SSHSession -ComputerName $Target -Credential $Cred -ConnectionTimeout 99999 -ErrorAction SilentlyContinue
        $SSHStream = New-SSHShellStream -SSHSession $session
        if ($error.Count -ne 0) {
            Write-Error $error.Item(0).Exception.Message
            exit
        }
        if ($session.Connected -eq $false) {
            Write-Error "New-SSHSession did not create a connected session"
            exit
        }
        Start-Sleep -Seconds 3
        $SSHStream.WriteLine("exit")
        $SSHStream.Close()
    } catch{
        throw "Password Verify Error, command output:" + $Output
    }

}
Invoke-HeartBeat -Target $args[0] -Username $args[1] -Password $args[2]