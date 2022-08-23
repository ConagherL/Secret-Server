[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
function Write-Log {
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline =$True)] $logItem
    )
    $LogPath = "C:\inetpub\wwwroot\secretserver\log\SS-PipeLineScriptErrors.txt"
    [string]$TimeStamp = Get-Date 
    "[$TimeStamp]: " + $logitem | Out-File -FilePath $LogPath -Append
}

function Get-Token {
    param (
        [Parameter(Mandatory=$True)]$URL,
        [Parameter(Mandatory= $True)]$username,
        [Parameter(Mandatory=$True)]$password,
        [switch]$ReturnToken
    )

        if(!$username -or !$password){
        $AuthToken = Get-Credential
        $username = $AuthToken.UserName
        $password = $AuthToken.GetNetworkCredential().Password
        }
    $creds = @{
        username = $UserName
        password = $Password
        grant_type = "password"
    }
    try{
        #Generate Token and build the headers which will be used for API calls.
        $token = (Invoke-RestMethod "$Url/oauth2/token" -Method Post -Body $creds -ErrorAction Stop).access_token
        $headers = @{Authorization="Bearer $token"}
        if($ReturnToken)
        {
            return $token
        }
        else{
            return $headers
        }
        
    }
    catch{
        
        throw "Authentication Error" + $_
    }   
    
}

function Remove-Token {
    param (
        [Parameter(Mandatory=$False)]$headers,
        [Parameter(Mandatory=$True)]$url

    )

    $ExpirePath = "$Url/api/v1/oauth-expiration" 
    

    $params = @{
        Header = $headers
        Uri = $ExpirePath
        ContentType = "application/json"
    }

    try{

            $ExpireToken = Invoke-RestMethod -Method POST @params -ErrorAction SilentlyContinue
            return $ExpireToken
        }
    catch{
        Write-Log $("Error Expiring Token: " + $_)
        Throw "Error Expiring Token: " + $_
    }
}

function Search-Secrets {
    param (
        [Parameter(Mandatory=$false)]$headers,
        [Parameter(Mandatory=$True)] $URL,
        [Parameter(Mandatory=$True)] $SecretName,
        [Parameter(Mandatory=$false)] $FolderID,
        [Parameter(Mandatory=$false)][switch]$UseWinAuth
    )
    if($UseWinAuth){$url += "/winauthwebservices"}
    $SearchPath = "$Url/api/v1/secrets?take=1000000&filter.searchText=$SecretName&filter.folderId=$FolderID&filter.includeRestricted=True&filter.isExactMatch=True"   
    $params = @{
        Header = $headers
        Uri = $SearchPath
        ContentType = "application/json"
    }

    try{
        if($UseWinAuth){
            $Secrets = Invoke-RestMethod -Method Get @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $Secrets
        }
        else{
            $Secrets = Invoke-RestMethod -Method Get @params -ErrorAction SilentlyContinue
            return $Secrets
        }
    }
    catch{
        Write-Log $("Secret Search Error on $SecretName" + $_)
    }
    
}


function Set-PrivilegedAccount {
    [cmdletbinding()]
    Param(
    [Parameter(Mandatory=$True,Position=0)]
    $Url,
    [Parameter(Mandatory=$True)]
    $token,
    [Parameter(Mandatory=$True)]
    $SecretID,
    [Parameter(Mandatory=$True)]
    $PrivSecretID
    )

    $SourceUrl = "$URL/webservices/SSWebservice.asmx?wsdl"
    $Proxy = New-WebServiceProxy -uri $SourceUrl -UseDefaultCredential -Namespace "ss"
    $codeResponseProp = @{
        ErrorCode = "COMMENT"
        Comment = "UpdatePrivilegedAccount Pipeline"
        }
    $coderesponse = new-object psobject -Property $codeResponseProp 
    $SecretToUpdate = $Proxy.GetSecret($Token,$SecretID,$True,$coderesponse)
    $SecretToUpdate.Secret.SecretSettings.PrivilegedSecretId = $PrivSecretID
    $SecretToUpdate.Secret.SecretSettings.IsChangeToSettings = $True
    $UpdatedPrivAccount = $proxy.UpdateSecret($token,$SecretToUpdate.Secret)
    If($updatedPrivAccount.error.count -ge 1){
        Throw "Error Updating Privileged Account" + $updatedPrivAccount.errors
    }
    else{
        return $True
    }
}

function Invoke-Pipeline {
    [cmdletbinding()]
    Param(
    [Parameter(Mandatory=$True,Position=0)]
    $domain,
    [Parameter(Mandatory=$True)]
    $username,
    [Parameter(Mandatory=$True)]
    $password,
    [Parameter(Mandatory=$True)]
    $PipelineSecretID,
    [Parameter(Mandatory=$True)]
    $PipelineMachineName,
    [Parameter(Mandatory=$True)]
    $PrivAccountFolderID,
    [Parameter(Mandatory=$True)]
    $PrivAccountUsername,
    [Parameter(Mandatory=$True)]
    $Url
    )
   
    try{
        $token = Get-Token -URL $url -username "$domain\$username" -password $password -returntoken   
        $headers = @{Authorization="Bearer $token"}
        $PrivAccount = Search-Secrets -headers $headers -url $url -SecretName "$PipelineMachineName\$PrivAccountUsername" -folderID $PrivAccountFolderID
        If($privAccount.records.count -eq 0){
            throw "No Privileged Secret Found"
        }
        elseif($privAccount.records.count -eq 1){
            Set-PrivilegedAccount -Url $url -token $token -SecretId $PipelineSecretID -PrivSecretId ($PrivAccount.Records)[0].id
        }
        elseif($privAccount.records.count -gt 1){
            foreach($record in $privaccount.records){
                if($record.HeartbeatStatus -eq "Success"){
                    Set-PrivilegedAccount -Url $url -token $token -SecretId $PipelineSecretID -PrivSecretId $record.id
                    break
                }
            }
        }
        $null = Remove-Token -headers $headers -url $url
    }
    catch{
        $null = Remove-Token -headers $headers -url $url
        throw "There was an error associating the privileged account: " + $_
    }
}

#Arguments:$[ADD:1]$DOMAIN $[ADD:1]$USERNAME $[ADD:1]$PASSWORD $SecretID $MACHINE(OR $HOST for ESXI) "FolderIDForPrivilegedAccountSearch" "UsernameOfPrivilegedAccountToSearchFor" "SSURL: IE https://SSURL/SecretServer"


$SecretID = $args[3]
$PipelineSecretID = [int32]$SecretID
$FolderId = $args[5]
$PrivAccountFolderID = [int32]$FolderId

Invoke-Pipeline  -domain $args[0] -username $args[1] -password $args[2] -PipelineSecretID $PipelineSecretID -PipelineMachineName $args[4] -PrivAccountFolderID $PrivAccountFolderID  -PrivAccountUsername $args[6] -Url $args[7]