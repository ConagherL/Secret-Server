[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    function Write-Log {
        param (
            [Parameter(Mandatory=$True,ValueFromPipeline =$True)] $logItem
        )
        $LogPath = "C:\logs\EventPipeLineLogs.txt"
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

    function Get-User {
        param (
            [Parameter(Mandatory=$False)] $headers,
            [Parameter(Mandatory=$True)] $url,
            [Parameter(Mandatory=$True)]$UserID,
            [Parameter(Mandatory=$False)][switch]$UseWinAuth
            )
        if($UseWinAuth){$url += "/winauthwebservices"}   
        $UserPath = "$Url/api/v1/Users/$UserID"  
    
        $params = @{
            Header = $headers
            Uri = $UserPath
            ContentType = "application/json"
        }
    
        try{
            if($UseWinAuth){
                $User = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                return $User
            }
            else{
                $User = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
                return $User
            }
        }
        catch{
            Write-Log $("User Retrieval Error on $UserID: " + $_)
        } 
    }
    
    function Update-User {
        param (
            [Parameter(Mandatory=$False)]$headers,
            [Parameter(Mandatory=$True)]$url,
            [Parameter(Mandatory=$True)]$UserObject,
            [switch]$UseWinAuth
        )
        if($UseWinAuth){$url += "/winauthwebservices"}
        $UserID = $Userobject.id
        $UserPath = "$Url/api/v1/users/$UserID" 
        
        $properties = @{
            "dateOptionId" = $User.dateOptionId
            "displayName" = $User.displayName
            "emailAddress" = $User.emailAddress
            "enabled" = $User.enabled
            "fido2TwoFactor" = $User.fido2TwoFactor
            "groupOwners" = $User.groupOwners
            "id" = $User.id
            "isApplicationAccount" = $User.isApplicationAccount
            "isGroupOwnerUpdate" = $false
            "isLockedOut" = $User.isLockedOut   
            "loginFailures" = $User.loginFailures   
            "oathTwoFactor" = $User.oathTwoFactor
            "password" = $User.password
            "radiusTwoFactor" = $User.radiusTwoFactor
            "radiusUserName" = $User.Username
            "timeOptionId" = $User.timeOptionId
            "twoFactor" = $User.twoFactor
                }
    
    #Put SecretChangePasswordArgs together, and convert them to JSON to be passed to the API
    $UpdateUserArgs = New-Object psObject -Property $properties | ConvertTo-Json
    
        $params = @{
            Header = $headers
            Uri = $UserPath
            body = $UpdateUserArgs
            ContentType = "application/json"
        }
    
        try{
            if($usewinauth){
                $UpdateUser = Invoke-RestMethod -Method PUT @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                return $UpdateUser
            }
            else{
                $UpdateUser = Invoke-RestMethod -Method PUT @params -ErrorAction SilentlyContinue
                return $UpdateUser
            }
            
    
        }
        catch{
            Write-Log $("User Update Error on $UpdateUser" + $_)
            throw "User Update Error on $UpdateUser" + $_
        }
    }
$url = "https://SSURL"
$headers = Get-Token -URL $url -Username $args[0] -Password $args[1]
$TargetUser = Get-User -headers $headers -url $url -UserID $args[2]
$updateUser = Update-User -headers $headers -url $url -UserObject $TargetUser