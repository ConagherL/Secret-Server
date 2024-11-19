# Windows Domain with domain name
# $SERVICENAME $MACHINE $[1]$DOMAIN $[1]$USERNAME $[1]$PASSWORD
$service = $args[0]
$computer =$args[1]
$Username = "$($args[2])\$($args[3])"
$Password = ConvertTo-SecureString -String $args[4] -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$password


Invoke-command -Computername $computer -cred $cred {
param($service)
Restart-Service -Name "$Service"
} -ArgumentList $service
