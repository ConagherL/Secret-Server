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
    Param(
    $SourceInstance,
    $DestinationInstance,
    $SourceFolderID,
    $DestinationFolderID,
    $Log,
    $SourceFolderName
         )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #Initialize variables
    $SourceUrl = "$SourceInstance/webservices/SSWebservice.asmx?wsdl"
    $DestinationUrl = "$DestinationInstance/webservices/SSWebservice.asmx?wsdl"

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

    $DuplicateTracker = @{}
    $LogMsg = "Running Job for folder: $SourceFolderName"
    $LogMsg | Out-File -FilePath $Log -Append
    $SourceSecrets = $SourceProxy.SearchSecretsByFolder($SourceToken,"",$SourceFolderID,$false,$false,$true)
    if($SourceSecrets.errors.count -gt 0)
                {
                    $LogMsg = "Error getting Source Secret Batch."
                    $LogMsg | Out-File -FilePath $Log -Append
                    $SourceSecret.Errors | Out-File -FilePath $log -Append
                    continue
                }
    $DestinationSecrets = $DestinationProxy.SearchSecretsByFolder($DestinationToken,"",$DestinationFolderID,$false,$false,$true)
    if($DestinationSecrets.errors.count -gt 0)
                {
                    $LogMsg = "Error getting Source Secret Batch."
                    $LogMsg | Out-File -FilePath $Log -Append
                    $DestinationSecrets.Errors | Out-File -FilePath $log -Append
                    continue
                }
    $LogMsg = "Pulled Secrets for $SourceFolderName, there are "+ $SourceSecrets.SecretSummaries.count + " Secrets in the source, and " + $DestinationSecrets.SecretSummaries.count  +" In the Destination"
    $LogMsg | Out-File -FilePath $Log -Append        

    $codeResponseProp = @{
        ErrorCode = "COMMENT"
        Comment = "API File Migration"
    }
    $coderesponse = new-object psobject -Property $codeResponseProp 

    foreach($SourceSecret in $SourceSecrets.SecretSummaries)
    {
        [bool]$Transfer = $false
        foreach($DestinationSecret in $DestinationSecrets.SecretSummaries)
        {
        #check to see if the secret is a duplicate by checking for the "---###" at the end. If it is a duplicate, then strip the duplicate name off for comparison.
            $file = $null
            #----------------------------------------------------
            $DestinationSecretName = $DestinationSecret.SecretName
            if($DestinationSecretName -like "*(*)")
            {
                $index = $DestinationSecretName.LastIndexOf("(")
                $substring = $DestinationSecretName.Substring(0,$index)
                $duplicateID = $DestinationSecretName.Substring($index+1)
                if($duplicateID -match "^\d+\)$")
                {
                    $DestinationSecretName = $substring
                } 
            }
            #check to see if secret name and template match.
            if($DestinationSecretName -eq $SourceSecret.SecretName -and $DestinationSecret.SecretTypeName -eq $SourceSecret.SecretTypeName)
            {
                
                [int] $SourceSecretID = $SourceSecret.Secretid
                [int] $DestinationSecretID = $DestinationSecret.SecretId
                $LogMsg = "Matched Source Secret $SourceSecretID, $SourceSecretName  With $DestinationSecretId, $DestinationSecretName"  
                $LogMsg | Out-File -FilePath $Log -Append   
                #in order to ensure that files are not overwritten, if the secret has already been migrated to, skip it.
                if($DuplicateTracker.ContainsValue($DestinationSecretID))
                {
                    $LogMsg = "Secret $DestinationSecretId, $DestinationSecretName Has already been migrated, Skipping."  
                    $LogMsg | Out-File -FilePath $Log -Append  
                    continue
                }
                $SourceSecretDetail = $SourceProxy.GetSecret($SourceToken,$SourceSecretID,$True,$coderesponse)
                if($SourceSecretDetail.errors.count -gt 0)
                {
                    $LogMsg = "Error getting Source Secret $SourceSecretName"
                    $LogMsg | Out-File -FilePath $Log -Append
                    $SourceSecretDetail.Errors | Out-File -FilePath $log -Append
                    continue
                }
                #iterate through each field on the source, and check to see if its a file.
                foreach($SourceField in $SourceSecretDetail.secret.items)
                {
                   # $LogMsg = "Checking Field is file = " + $Sourcefield.isfile + " On " + $SourceSecretName
                   #  $LogMsg | Out-File -FilePath $Log -Append   
                    if($SourceField.isfile -eq $true)
                    {
                        $file = $SourceProxy.DownloadFileAttachmentByItemId($SourceToken, $SourceSecretDetail.Secret.Id, $SourceField.Id)
                        #if the file on the source is empty, skip it.
                        if(!$file.fileattachment)
                        {
                            continue
                        }
                        $DestinationSecretDetail = $DestinationProxy.GetSecret($DestinationToken,$DestinationSecretID,$True,$coderesponse)
                        if($DestinationSecretDetail.errors.count -gt 0)
                        {
                            $LogMsg = "Error getting Destination Secret $DestinationSecretName"
                            $LogMsg | Out-File -FilePath $Log -Append
                            $DestinationSecretDetail.Errors | Out-File -FilePath $log -Append
                            continue
                        }
                        foreach($TargetField in $DestinationSecretDetail.secret.items)
                        {
                            if($SourceField.FieldName -eq $TargetField.FieldName)
                            {
                                    $LogMsg = $("Checking Fieldname" + $SourceField.fieldname + "on " + $SourceSecretName)
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
                                    $LogMsg = "Currently migrating file: $SourceFileName on secret: $SourceSecretName in folder: $SourceFolderName to Secret: $DestinationSecretName"
                                    $LogMsg | Out-File -FilePath $Log -Append
                                    #Set Transfer to true to exit loop to prevent overwriting of files.
                                    $DuplicateTracker.add($SourceSecretID,$DestinationSecretID) 
                                    $Transfer = $true
                                    
                                    # Failed upload
                                    if($uploadResult.Errors.Count -gt 0) {
                                        $ErrorInfo = "FAIL: file: $SourceFileName on secret: $SourceSecretName in folder: $SourceFolderName to Secret: $DestinationSecretName"
                                        $ErrorInfo | Out-File -FilePath $Log -Append
                                        $uploadResult | Out-File -FilePath $Log -Append
                                    }
                                    # Successful upload
                                    else {
                                        $SuccessInfo = "SUCCESS: file: $SourceFileName on secret: $SourceSecretName in folder: $SourceFolderName to Secret: $DestinationSecretName"
                                        $SuccessInfo | Out-File -FilePath $Log -Append
                                    }  
                            }                                        
                        }
                    }
                }    
            }
            if($Transfer -eq $true)
            {
                Break
            }
        }
    }
    if(!$DuplicateTracker)
    {
        $LogMsg = "Job Completed, NO FILES MIGRATED for Folder $SourceFolderName"  
        $LogMsg | Out-File -FilePath $Log -Append  
    }          
}
                        
    MigrateFile -SourceInstance "https://SSURL/SecretServer" -DestinationInstance "https://secretservercloud.com" -SourceFolderID "" -DestinationFolderID "" -SourceFolderName "FolderName" -log "C:\Migration\testlog.txt"


                        