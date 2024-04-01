[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$AuthToken = Get-Credential
$username = $AuthToken.UserName
$password = $AuthToken.GetNetworkCredential().Password

$Url = "http://"

function Write-Log {
    param (
        [Parameter(Mandatory=$True,ValueFromPipeline =$True)] $logItem
    )
    $LogPath = "C:\migration\New-SecretGenerationLog.txt"
    [string]$TimeStamp = Get-Date
    "[$TimeStamp]: " + $logitem | Out-File -FilePath $LogPath -Append
}

function Get-Headers {
    param (
        [Parameter(Mandatory=$True)] $URL,
        [Parameter(Mandatory=$True)] $username,
        [Parameter(Mandatory=$True)] $password,
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


function Update-Folder {
    param (
        [Parameter(Mandatory=$False)]$headers,
        [Parameter(Mandatory=$True)]$url,
        [Parameter(Mandatory=$True)]$Folder,
        [switch]$UseWinAuth
    )
    if($UseWinAuth){$url += "/winauthwebservices"}
    $FolderPath = "$Url/api/v1/folders/" + $folder.id

    $properties = @{
        "id" = $Folder.Id
        "folderTypeId" = $folder.folderTypeId
        "parentFolderId" = $folder.parentFolderId
        "secretPolicyId" = $folder.parentFolderId
        "folderName" = $folder.folderName
        "inheritPermissions" = $folder.inheritPermissions
        "inheritSecretPolicy" = $folder.inheritSecretPolicy
            }

#Put SecretChangePasswordArgs together, and convert them to JSON to be passed to the API
$UpdateFolderArgs = New-Object psObject -Property $properties | ConvertTo-Json

    $params = @{
        Header = $headers
        Uri = $FolderPath
        body = $UpdateFolderArgs
        ContentType = "application/json"
    }

    try{
        if($usewinauth){
            $UpdateFolder = Invoke-RestMethod -Method PUT @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $UpdateFolder
        }
        else{
            $UpdateFolder = Invoke-RestMethod -Method PUT @params -ErrorAction SilentlyContinue
            return $UpdateFolder
        }


    }
    catch{
        Write-Log $("Folder Create Error on $UpdateFolder" + $_)
    }
}

function Search-Folders {
    param (
        [Parameter(Mandatory=$False)]$headers,
        [Parameter(Mandatory=$True)]$url,
        [Parameter(Mandatory=$False)]$FolderName,
        [switch]$UseWinAuth
    )
    if($UseWinAuth){$url += "/winauthwebservices"}
    $FolderPath = "$Url/api/v1/folders?take=10000&filter.searchText=$FolderName"

    $params = @{
        Header = $headers
        Uri = $FolderPath
        ContentType = "application/json"
    }

    try{
        if($usewinauth){
            $SearchFolder = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $SearchFolder
        }
        else{
            $SearchFolder = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
            return $SearchFolder
        }
    }
    catch{
        Write-Log $("Search Folder Error on $SearchFolder" + $_)
    }
}


$headers = Get-headers -url $url -username $username -password $password
$folders = Search-Folders -headers $headers -url $Url
foreach($folder in $folders.records){
    if(!$folder.inheritSecretPolicy){
        $folder.inheritSecretPolicy = $true
        Write-Host "Updating Folder " $folder.folderName
        Update-Folder -headers $headers -url $Url -Folder $folder
    }

}