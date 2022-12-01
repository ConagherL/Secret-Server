### Check for Thycotic PS Module
try { 
    Import-Module -Name Thycotic.SecretServer -MinimumVersion "0.60.0" -ErrorAction stop 
}
catch { 
    Write-Host -ForegroundColor red "Thycotic.Secretserver release 0.60.0 or greater required" 
    break 
}

### Production Authentication
$prodcred = Get-Credential
$prouri = 'https://blt.secretservercloud.com'
$prodsession = New-TssSession -SecretServer $prouri -Credential $prodcred

### DR Authentication
$drcred = Get-Credential
$druri = 'http://ssdr.blt.local/SecretServer'
$drsession = New-TssSession -SecretServer $druri -Credential $drcred


### Grab all secrets access during the DR window

$DRreportid = 94
$DRFileName = 'DR_Secrets.csv'
$ExportDirectory = 'C:\Temp'
$Path = $ExportDirectory + '\' + $DRFileName
# Check if file exsits and delete
if (Test-Path $Path) {
    Remove-Item $Path
    write-host "$Path has been deleted"
  }
else {
    Write-Host "$path doesn't exsit. Creating DR_Secrets.csv file"
}
# Execute the report and create a file called DR_Secrets.csv with the contents of the report
Invoke-TssReport -TssSession $DRsession -Id $DRReportID | Export-Csv $Path -NoClobber -NoTypeInformation


### Loop through all secret names and execute a expiration action
###$secretnames = Import-Csv -Path $Path 
foreach ($name in (Import-Csv -Path $Path )) {
    $target = Find-TssSecret -TssSession $prodsession -SearchText $name.'Secret Name'
    Invoke-TssRestApi -Uri "$prouri/api/v1/secrets/$($target.id)/expire" -PersonalAccessToken $prodSession.AccessToken -Method POST
    $target=$null

}

