<#
    .SYNOPSIS
    Use this script as a test script to validate arguments being passed into the script from Secret Server

    .NOTES
    Adjust code based on arguments being tested and how you want the log file content to be written.

    You can use this as a template, starting point.

    .EXAMPLE
    Expected Arguments: "$[ADD:1]$URL" "$[ADD:1]$USERNAME" "$[ADD:1]$PASSWORD" "$SecretId" "private-key" "$PRIVATEKEY" "$SYNC"
    Run this script with the above as arguments and they are written to a file
#>
[array]$params = $args
$logFile = 'c:\thycotic\eventpipeline_script_arguments.txt'
Remove-Item $logFile -Force -EA SilentlyContinue

$argument1 = $params[0]
$argument2 = $params[1]
$argument3 = $params[2]
$argument4 = $params[3]
$argument5 = $params[4]
$argument6 = $params[5]
$argument7 = $params[6]

Add-Content -Path $logFile -Value "Argument Value: $argument1"
Add-Content -Path $logFile -Value "Argument Value: $argument2"
Add-Content -Path $logFile -Value "Argument Value: $argument3"
Add-Content -Path $logFile -Value "Argument Value: $argument4"
Add-Content -Path $logFile -Value "Argument Value: $argument5"
Add-Content -Path $logFile -Value "Argument Value: $argument6"
Add-Content -Path $logFile -Value "Argument Value: $argument7"
