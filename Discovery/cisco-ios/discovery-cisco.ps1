$params = $args
$hostaddress = $params[0]
$username = $params[1]
$password = $params[2]
$enable = $params[3]
$commands = $params[4]

# Open SSH stream session, passes IOS commands, reads stream and parses account info
# This script leverages WMF 5.0 and checks if it is installed
if ($PSVersionTable.PSVersion.Major -lt 5) {
    throw "PowerShell version on server is not the latest version. Please install Windows PowerShell 5.1"
}
if (-not (Get-Module Posh-SSH -List)) {
    throw "Posh-SSH PowerShell module is missing. Please install module from the PowerShell Gallery"
}

# Default to port 22 if not provided
if ($port.Length -eq 0) { $port = "22" }

try {
    $TERM = "msys"
    $secpasswd = ConvertTo-SecureString $password -AsPlainText -Force
    $creds = New-Object System.Management.Automation.PSCredential($username,$secpasswd)

    # Creates session and hides output
    $null = New-SSHSession -ComputerName $hostaddress -port $port -AcceptKey -Credential $creds

    # Run all the commands that were originally passed as arguments
    foreach ($command in $commands) {
        #Figure out what your SSH session is
        $session = Get-SSHSession  -Computername $hostaddress

        #Then build a stream for it (we only need to do this once per host)
        if ($stream -eq $null) {
            $stream = $session.Session.CreateShellStream("xterm", 1000, 1000, 1000, 1000, 1000)
        }

        # We have to give the stream a few seconds to build the terminal (otherwise all of the commands will get passed before the terminal has had a chance to finish creation)
        Start-Sleep -Seconds 2

        # Read the stream, press enter and then clear that from the buffer
        $streamoutput = $stream.read()

        # Checks for IOS Enable password and writes to stream
        if (![string]::IsNullOrEmpty($enable)) {
            $stream.write("enable`n")
            $stream.write("$enable`n")
        }

        # Enters commands and clears
        $stream.Write("$commands`n")
        Clear-Variable streamoutput
        Start-Sleep -Seconds 1

        # We did just nuke this object, so lets go ahead and redefine it
        $streamoutput = $stream.Read()

        # Splits revelant portions of output
        $array = $streamoutput -split "i user"
        $ciscoProperties = $array[1] -split "end of script"
        $properties = $ciscoProperties -split '\n'
        $ciscoAccounts = @()

        for ($i = 0; $i -lt $properties.Count; $i++) {
            if ($properties[$i].Length -ne 0) {
                $ciscoAccounts += $properties[$i]
            }
        }

        # Remove SSH Session and hides output again
        Remove-SSHSession -SSHSession $session | Out-Null

    }
} catch [Exception] {
    $ErrorMessage += "This Error occurred:  "
    $ErrorMessage += $_.Exception.Message
    throw $ErrorMessage
    break
}

$accounts = New-Object System.Collections.ArrayList
$count = $ciscoAccounts.Count

for ($i = 0; $i -lt $count; $i++) {

    $arr = $ciscoAccounts[$i].Split(" ")

    $info = [PSCustomObject]@{
        Username = $username
        Level    = $level
        Password = $password
    }

    $info.username = $arr[1]
    $info.level = $arr[2] + " " + $arr[3]

    if ($arr[2] -eq "secret") {
        $info.password = $arr[4]
    } else { $info.password = $arr[6] }

    if ($info.username) { $blah = $accounts.Add($info) }
}
$accounts
