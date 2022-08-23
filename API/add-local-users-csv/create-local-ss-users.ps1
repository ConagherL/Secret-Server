$username = ""
$password = ""
$SSUrl = "https://SSURL"

$CSV = Import-CSV -path "c:\Migration\UserMAP.csv"
#script will need to ingest a CSV with the following columns / Headers: userName,password,displayName,emailAddress,DomainId
#note that each user's Domain ID for Local Users should be "-1"
    function Get-Headers {
        param (
            $URL,
            $username,
            $password,
            [switch]$ReturnToken
        )
        #Input creds
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

    function New-User {
        param (
         $headers,
         $Url,
         $UserObject
        )
        #Create the properties for the secret. 
     $properties = @{
         "userName" = $UserObject.userName
         "password" = $UserObject.password
         "displayName" = $UserObject.displayName
         "enabled" = $true
         "emailAddress" = $UserObject.emailAddress
         "domainId" = $UserObject.domainId
         "radiusUserName" = $null
         "twoFactor" = $False
         "radiusTwoFactor" = $False
         "isApplicationAccount" = $False
         "oathTwoFactor" = $False
         "duoTwoFactor" = $False
         "fido2TwoFactor" = $False
         "adGuid" = $null
             }
 #Put New User Args together, and convert them to JSON to be passed to the API
 $NewUserArgs = New-Object psObject -Property $properties | ConvertTo-Json
 
 $params = @{
     Header = $headers
     Uri = "$Url/api/v1/Users"
     body = $NewUserArgs
     ContentType = "application/json"
     }
     try{
         $NewUser = Invoke-RestMethod -Method POST @params -ErrorAction SilentlyContinue
         return $NewUser   
     }
     catch{
        [string]$time = Get-Date
         throw $($time + "User Creation Error on $UserObject" + $_)
     }    
}

$headers = Get-Headers -URL $SSUrl -username $username -password $password

foreach($row in $CSV){

    $properties = @{
        "userName" = $row.username
        "password" = $row.password
        "displayName" = $row.displayName
        "emailAddress" =  $row.EmailAddress
        "DomainId" = $row.domainId
    }
    
    $UserObject = New-Object psObject -Property $properties
    try{
        write-host "Creating User:" + $row.displayname
        $NewUser = New-User -headers $headers -Url $SSUrl -UserObject $UserObject
    }
    catch{
        throw $($time + "User Creation Error on $UserObject" + $_)
    }
    
}

