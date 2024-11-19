[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$Url = "https://ps01.thycotic.blue/SecretServer" #Enter you Secret Server URL Here. Webservices will need to be enabled in order for this script to run. 
$TemplateID = '6083' #Enter the ID of the template you want to find the dependencies associated with to Delete
$LogPath = "C:\migration\DeleteDependency.txt" #this path needs to resolve, so it will be able to write logs for any errors that occur. 

    function Write-Log {
        param (
            [Parameter(Mandatory=$True,ValueFromPipeline =$True)] $logItem
        )
        [string]$TimeStamp = Get-Date 
        "[$TimeStamp]: " + $logitem | Out-File -FilePath $LogPath -Append
    }

    function Get-Token {
        param (
            $URL,
            [Parameter(Mandatory=$False)]
            $username,
            [Parameter(Mandatory=$False)]
            $password,
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

    function Search-SecretByTemplateID {
        param (
            [Parameter(Mandatory=$false)]$headers,
            [Parameter(Mandatory=$True)] $URL,
            [Parameter(Mandatory=$True)] $TemplateID,
            [Parameter(Mandatory=$false)][switch]$UseWinAuth
        )
        if($UseWinAuth){$url += "/winauthwebservices"}
        $SearchPath = "$Url/api/v1/secrets?take=1000000&filter.TypeId=$TemplateID&filter.includeRestricted=True"   
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
            Write-Log $("Secret Search Error on TemplateID: $TemplateID" + $_)
        }
        
    }
    
    function Search-DependencyBySecretID {
        param (
            [Parameter(Mandatory=$false)]$headers,
            [Parameter(Mandatory=$True)] $URL,
            [Parameter(Mandatory=$True)] $SecretID,
            [Parameter(Mandatory=$false)][switch]$UseWinAuth
        )
        if($UseWinAuth){$url += "/winauthwebservices"}
        $SearchPath = "$Url/api/v1/secret-dependencies?take=1000000&filter.secretId=$SecretID"   
        $params = @{
            Header = $headers
            Uri = $SearchPath
            ContentType = "application/json"
        }
    
        try{
            if($UseWinAuth){
                $Dependency = Invoke-RestMethod -Method Get @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                return $Dependency
            }
            else{
                $Dependency = Invoke-RestMethod -Method Get @params -ErrorAction SilentlyContinue
                return $Dependency
            }
        }
        catch{
            Write-Log $("Dependency Search Error on SecretID: $SecretID" + $_)
        }
        
    }
    
    function Remove-Dependency {
        param (
            [Parameter(Mandatory=$false)] $headers,
            [Parameter(Mandatory=$True)]$url,
            [Parameter(Mandatory=$True)]$DependencyID,
            [switch]$UseWinAuth
        )
        if($UseWinAuth){$url += "/winauthwebservices"}
        $SecretPath = "$Url/api/v1/secret-dependencies/$DependencyID"  
    
    
        $params = @{
            Header = $headers
            Uri = $SecretPath
            ContentType = "application/json"
        }
    
        try{
            $Dependency = Invoke-RestMethod -Method Delete @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $Dependency
    
        }
        catch{
            Write-Log -logitem $("Dependency Deletion Error on ID: $DependencyID" + $_)
        } 
    }
    
    
    
    $headers = Get-Token -URL $Url -username $username -password $password 
    $Secrets = Search-SecretByTemplateID -headers $headers -URL $URL -TemplateID $TemplateID
    Write-host "Beginning Dependency Deletion Script"
    Foreach($Secret in $Secrets.records){
        $dependencies = Search-DependencyBySecretID -headers $headers -URL $url -SecretID $secret.id
        Write-host "Checking Secret" + $Secret.name
        foreach($dependency in $dependencies.records){
            Write-host "Deleting Dependency: " + $Dependency.name
            $response = Remove-Dependency -headers $headers -url $url -DependencyID $dependency.id
            Write-Log -logitem $response
        }
    }