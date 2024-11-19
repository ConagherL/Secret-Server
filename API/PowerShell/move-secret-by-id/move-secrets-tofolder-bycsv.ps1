[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
#IMPORTANT: please ensure that you update the values on line(s) 10, 149, 155 and 158 before running.


    function Write-Log {
        param (
            [Parameter(Mandatory=$True,ValueFromPipeline =$True)] $logItem
        )
        #Log path will need to be updated to a path that exists. Any errors that are encoutered will be logged in this location. 
        $LogPath = "C:\temp\SecretMoveLog.txt"
        [string]$TimeStamp = Get-Date 
        "[$TimeStamp]: " + $logitem | Out-File -FilePath $LogPath -Append
    }

    function Get-Token {
        param (
            [Parameter(Mandatory=$True)]$URL,
            [Parameter(Mandatory= $False)]$username,
            [Parameter(Mandatory=$False)]$password,
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

    function Get-Secret {
        param (
            [Parameter(Mandatory=$false)] $headers,
            [Parameter(Mandatory=$True)]$url,
            [Parameter(Mandatory=$True)]$SecretId,
            [switch]$UseWinAuth
        )
        if($UseWinAuth){$url += "/winauthwebservices"}
        $SecretPath = "$Url/api/v1/secrets/$SecretId/restricted"  
    
        $properties = @{
        IncludeInactive = $true 
        NewPassword = $null
        DoubleLockPassword = $null  
        TicketNumber = ""
        TicketSystemId = ""
        Comment = "SecretCreationScript"
        ForceCheckIn = $true
        }
        $SecretRestrictedArgs = New-Object psObject -Property $properties | ConvertTo-Json
        $params = @{
            Header = $headers
            Uri = $SecretPath
            Body = $SecretRestrictedArgs
            ContentType = "application/json"
        }
    
        try{
            $Secret = Invoke-RestMethod -Method Post @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $Secret
    
        }
        catch{
            Write-Log $("Secret Retrieval Error on $SecretID" + $_)
        } 
    }

function Update-Secret {
    param (
        [Parameter(Mandatory=$False)]$headers,
        [Parameter(Mandatory=$True)]$url,
        [Parameter(Mandatory=$True)]$SecretID,
        [Parameter(Mandatory=$True)]$SecretObject,
        [switch]$UseWinAuth
    )
    if($UseWinAuth){$url += "/winauthwebservices"}
    $SecretPath = "$Url/api/v1/secrets/$SecretId/" 
    
    $properties = @{
        "id" = $SecretObject.Id
        "name" = $SecretObject.name
        "folderId" = $SecretObject.folderId
        "active" = $SecretObject.active
        "items" = $SecretObject.items
        "launcherConnectAsSecretId" = $SecretObject.launcherConnectAsSecretId
        "autoChangeEnabled" = $SecretObject.autoChangeEnabled
        "requiresComment" = $SecretObject.requiresComment
        "checkOutEnabled" = $SecretObject.checkOutEnabled
        "checkOutIntervalMinutes" = $SecretObject.checkOutIntervalMinutes
        "checkOutChangePasswordEnabled" = $SecretObject.checkOutChangePasswordEnabled
        "proxyEnabled" = $SecretObject.proxyEnabled
        "sessionRecordingEnabled" = $SecretObject.sessionRecordingEnabled
        "passwordTypeWebScriptId" = $SecretObject.passwordTypeWebScriptId
        "siteId" = $SecretObject.siteId
        "enableInheritPermissions" = $SecretObject.enableInheritPermissions
        "enableInheritSecretPolicy" = $SecretObject.enableInheritSecretPolicy
        "secretPolicyId" = $SecretObject.secretPolicyId
        "autoChangeNextPassword" = $SecretObject.autoChangeNextPassword
        "sshKeyArgs" = $SecretObject.sshKeyArgs
            }
    $UpdateSecretArgs = New-Object psObject -Property $properties | ConvertTo-Json
    $params = @{
        Header = $headers
        Uri = $SecretPath
        body = $UpdateSecretArgs
        ContentType = "application/json"
    }

    try{
        if($usewinauth){
            $UpdateSecret = Invoke-RestMethod -Method PUT @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $UpdateSecret
        }
        else{
            $UpdateSecret = Invoke-RestMethod -Method PUT @params -ErrorAction SilentlyContinue
            return $UpdateSecret
        }
        

    }
    catch{
        Write-Log $("Secret Update Error on $UpdateSecret" + $_)
    }
}

#Please enter the Secret Server Full url, if your SSURL is "https://secretserver.domain.com/secretserver", please include the /secretserver, ensure there's no trailing slash.
$url = "https://SSURL"

#Script will prompt for username and password at run time. If you are using a domain user please enter domain\username in the username field. 
$headers = Get-Token -Url $url 

#update CSV path to the csv object that we will be iterating through. There must be a column named "SecretID" within it, that contains all of the secrets you wish to move. 
$CSV = Import-CSV "C:\PathTo\IDLIST.csv"

#This value is the ID of the folder to move the secrets to. You can obtain the folder ID by browsing to the folder in the UI and pulling it from the address bar. for example: https://secretserver.domain.com/secretserver/app/#/folders/77, 77 is the folder ID. 
$TargetFolderID = "77"

#iterate through the CSV, and get / move secrets to the new destination folder. 
foreach($row in $CSV){
    $SecretObject = Get-Secret -headers $headers -url $url -SecretId $row.SecretID
    $SecretObject.folderId = $TargetFolderID
    Write-Host "Moving Secret: " $SecretObject.name " to Folder ID: " $TargetFolderID
    $null = Update-Secret -url $url -headers $headers -SecretID $SecretObject.id -SecretObject $SecretObject
}