Function Get-Token
{
[cmdletbinding()]
Param(
[Parameter(Mandatory=$True,Position=0)]
$WebProxy,
[Parameter(Mandatory=$False)]
$Domain,
[Parameter(Mandatory=$False)]
$OrgCode,
[Parameter(Mandatory=$False)]
$MFAToken

)
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #Enter HardCoded Credentials, or use Get-Credential Method to input username and password.

    $AuthToken = Get-Credential
    $username = $AuthToken.UserName
    $password = $AuthToken.GetNetworkCredential().Password
            
    # Define the user credentials 
    # $username = "" 
    # $password = ""
    if(!$OrgCode)
    {
        $OrgCode = ""
    }
    if(!$Domain)
    {
        $Domain = "local"
    }
    if(!$MFAToken)
    {
        $tokenResult = $WebProxy.Authenticate($username, $password, $OrgCode, $domain)
        if($tokenResult.Errors.Count -gt 0)
        {
            Write-Output "Authentication Error: " $tokenResult.Errors[0]
            Return
        }
    }
    else
    {
        $tokenResult = $WebProxy.Authenticate($username, $password, $OrgCode, $domain,$MFAToken)
        if($tokenResult.Errors.Count -gt 0)
        {
            Write-Output "Authentication Error: " $tokenResult.Errors[0]
            Return
        }
    }
    $token = $tokenResult.Token

    return $token

}
function MigrateFile {
    param (
        [Parameter(Mandatory=$True)]
        [string]$SourceFQDN,
        [Parameter(Mandatory=$True)]
        [string]$DestinationFQDN,
        [Parameter(Mandatory=$True)]
        $DestinationProxy,
        [Parameter(Mandatory=$True)]
        [string]$DestinationToken,
        [Parameter(Mandatory=$True)]
        [string]$SourceToken,
        [Parameter(Mandatory=$True)]
         $SourceProxy,
        [Parameter(Mandatory=$True)]
        [int]$SourceSecretID,
        [Parameter(Mandatory=$True)]
        [int]$DestinationSecretID,
        [Parameter(Mandatory=$false)]
        $log = "C:\Migration\ssfilemigrationsingle.txt"
    )
                            [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
                            #Initialize variables


                            $SourceUrl = "$SourceFQDN/webservices/SSWebservice.asmx?wsdl"
                            $DestinationUrl = "$DestinationFQDN/webservices/SSWebservice.asmx?wsdl"

                           
                            $SourceSecretDetail = $SourceProxy.GetSecret($SourceToken,$SourceSecretID,$True,$coderesponse)
                            if($SourceSecretDetail.errors.count -gt 0)
                            {
                                $LogMsg = "Error getting Source Secret $SourceSecretName"
                                Write-Host $logmsg
                                $LogMsg | Out-File -FilePath $Log -Append
                                $SourceSecretDetail.Errors | Out-File -FilePath $log -Append
                                continue
                            }
                            #iterate through each field on the source, and check to see if its a file.
                            foreach($SourceField in $SourceSecretDetail.secret.items)
                            {
                                $LogMsg = "Checking Field is file = " + $Sourcefield.isfile + " On " + $SourceSecretName
                                Write-Host $logmsg
                                $LogMsg | Out-File -FilePath $Log -Append   
                                if($SourceField.isfile -eq $true)
                                {
                                    $file = $SourceProxy.DownloadFileAttachmentByItemId($SourceToken, $SourceSecretDetail.Secret.Id, $SourceField.Id)
                                    $LogMsg = $("Checking Checking Source File "+ $File)
                                    $LogMsg | Out-File -FilePath $Log -Append
                                    #if the file on the source is empty, skip it.
                                    if(!$file.fileattachment)
                                    {
                                        continue
                                    }
                                    $DestinationSecretDetail = $DestinationProxy.GetSecret($DestinationToken,$DestinationSecretID,$True,$coderesponse)
                                    if($DestinationSecretDetail.errors.count -gt 0)
                                    {
                                        $LogMsg = "Error getting Destination Secret " + $DestinationSecretDetail.Secret.Name + " Errors: " + $DestinationSecretDetail.Errors 
                                        Write-Host $logmsg
                                        $LogMsg | Out-File -FilePath $Log -Append
                                        $DestinationSecretDetail.Errors | Out-File -FilePath $log -Append
                                        continue
                                    }
                                    foreach($TargetField in $DestinationSecretDetail.secret.items)
                                    {
                                        if($SourceField.FieldName -eq $TargetField.FieldName)
                                        {
                                                $LogMsg = $("Checking Fieldname" + $SourceField.fieldname + "on " + $SourceSecretDetail.Secret.Name)
                                                Write-Host $logmsg
                                                $LogMsg | Out-File -FilePath $Log -Append
                                                # Build Variables for Logging
                                                $SourceSecretName = $SourceSecret.SecretName
                                                $SourceFileName = $file.FileName
                                                
                                                
                                                # Upload to Destination
                                                try{
                                                    $uploadResult = $DestinationProxy.UploadFileAttachmentByItemId($DestinationToken, $DestinationSecretDetail.Secret.id, $TargetField.Id, $file.FileAttachment, $file.FileName)
                                                }
                                                catch
                                                {
                                                   $_.exception | Out-File -FilePath $log -Append
                                                }                                                
                                                # Write to log
                                                $LogMsg = "Currently migrating file: $SourceFileName on secret: "+ $SourceSecretDetail.Secret.Name +" in folder: $SourceFolderName to Secret: " + $DestinationSecretDetail.Secret.Name
                                                Write-Host $logmsg
                                                $LogMsg | Out-File -FilePath $Log -Append
                                                #Set Transfer to true to exit loop to prevent overwriting of files.
                                                $Transfer = $true
                                                
                                                # Failed upload
                                                if($uploadResult.Errors.Count -gt 0) {
                                                    $ErrorInfo = "FAIL: file: $SourceFileName on secret: " + $SourceSecretDetail.Secret.Name +" in folder: $SourceFolderName to Secret: " + $DestinationSecretDetail.Secret.Name
                                                    Write-Host $ErrorInfo
                                                    $ErrorInfo | Out-File -FilePath $Log -Append
                                                    $uploadResult | Out-File -FilePath $Log -Append
                                                }
                                                # Successful upload
                                                else {
                                                    $SuccessInfo = "SUCCESS: file: $SourceFileName on secret: "+ $SourceSecretDetail.Secret.Name +" in folder: $SourceFolderName to Secret: " + $DestinationSecretDetail.Secret.Name
                                                    Write-Host $SuccessInfo
                                                    $SuccessInfo | Out-File -FilePath $Log -Append
                                                }  
                                        }                                        
                                    }
                                }
                            } 
                        }

                            $SourceFQDN = "" 
                            $DestinationFQDN = "" 
                            $SourceUrl = "$SourceFQDN/webservices/SSWebservice.asmx?wsdl"
                            $DestinationUrl = "$DestinationFQDN/webservices/SSWebservice.asmx?wsdl"

                            $SourceProxy = New-WebServiceProxy -uri $SourceUrl -UseDefaultCredential -Namespace "ss"
                            $DestinationProxy = New-WebServiceProxy -uri $DestinationUrl -UseDefaultCredential -Namespace "ss"

                            Write-Host "Generating Source Access Token"
                            $SourceToken = Get-Token -WebProxy $SourceProxy -Domain $Domain -OrgCode $OrgCode -MFAToken $MFAToken
                            if($SourceToken -like "Authentication Error:*")
                            {
                                throw "Source Login Error: $SourceToken" 
                            }
                            Write-Host "Generating Destination Access Token"
                            $DestinationToken = Get-Token -WebProxy $DestinationProxy -Domain $Domain -MFAToken $MFAToken
                            if($DestinationToken -like "Authentication Error:*")
                            {
                                throw "Destination Login Error: $DestinationToken" 
                            }


                        
                        $CSV = Import-CSV "C:\SecretServer_Migration\IDMAP.csv"
                     foreach($row in $CSV){
                            MigrateFile -SourceFQDN $sourceFQDN -DestinationFQDN $DestinationFQDN -SourceToken $SourceToken -SourceProxy $SourceProxy -destinationToken $DestinationToken -DestinationProxy $DestinationProxy -SourceSecretID $row.SourceID -DestinationSecretID $row.DestinationId
                        }

                        