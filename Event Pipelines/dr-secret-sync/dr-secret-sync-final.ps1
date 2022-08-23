[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log {
    param (
        [Parameter(Mandatory = $True,ValueFromPipeline = $True)] $logItem
    )
    $LogPath = "C:\Program Files\Thycotic Software Ltd\Distributed Engine\log\SyncLog.txt"

    [string]$TimeStamp = Get-Date
    "[$TimeStamp]: " + $logitem | Out-File -FilePath $LogPath -Append
    <#
        .SYNOPSIS
        Writes Script Logs to a location locally.

        .DESCRIPTION
        This method will allow for the logging of script items and to a specified log location. It will append a date time stamp to differentiate log messages.

        .PARAMETER LogItem
        Specifies the log item you want to be written to the specified location.

        .INPUTS
        -LogItem. You cannot pipe objects to Get-Token.

        .OUTPUTS
        None, this method will output to the log location. No return to terminal.

        .EXAMPLE
        PS> Write-Log $("This is an example log message.")

        .EXAMPLE
        PS> Get-Service | Write-Log
    #>
}
function Get-Token {
    param (
        [Parameter(Mandatory = $True  )]
        $URL,
        [Parameter(Mandatory = $False)]
        $username,
        [Parameter(Mandatory = $False)]
        $password,
        [switch]$ReturnToken
    )
    $creds = @{
        username   = $UserName
        password   = $Password
        grant_type = "password"
    }
    try {
        #Generate Token and build the headers which will be used for API calls.
        $token = (Invoke-RestMethod "$Url/oauth2/token" -Method Post -Body $creds -ErrorAction Stop).access_token
        $headers = @{Authorization = "Bearer $token" }
        if ($ReturnToken) {
            return $token
        } else {
            return $headers
        }

    } catch {

        throw "Authentication Error to $url : " + $_
    }
    <#
        .SYNOPSIS
        Queries the REST API to provide an OAUTH Token.

        .DESCRIPTION
        By Default the method will provide pre-formatted headers that can be passed directly into our REST API endpoints. There is also a "ReturnToken" swich which will return just the oauth token without the header formatting.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER Username
        Username to authenticate to the REST API as. If authenticating with a domain account, qualify the domain into the username. DOMAIN\Username. If either username or password are not specified, the method will prompt for user input.

        .PARAMETER Password
        Password for the user being submitted. If either username or password are not specified, the method will prompt for user input.

        .PARAMETER ReturnToken
        Returns just the oauth2 token, without header formatting.

        .INPUTS
        None. You cannot pipe objects to Get-Token.

        .OUTPUTS
        System.String. Get-Token either returns formatted headers, or a string token.

        .EXAMPLE
        PS> Get-Token -url $url -Username $username -password $password

        .EXAMPLE
        PS> Get-Token -url $url
    #>
}
function Remove-Token {
    param (
        [Parameter(Mandatory = $True)]$headers,
        [Parameter(Mandatory = $True)]$url

    )
    $ExpirePath = "$Url/api/v1/oauth-expiration"


    $params = @{
        Header      = $headers
        Uri         = $ExpirePath
        ContentType = "application/json"
    }

    try {

        $ExpireToken = Invoke-RestMethod -Method POST @params -ErrorAction SilentlyContinue
        return $ExpireToken
    } catch {
        Write-Log $("Error Expiring Token: " + $_)
        Throw "Error Expiring Token: " + $_
    }
    <#
        .SYNOPSIS
        Expires the OAUTH token that's been passed into this method.

        .DESCRIPTION
        This method expires the OAUTH token that's been provided. This ends the current user's API session, and will require authentication before being able to conduct more commands.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .INPUTS
        None.

        .OUTPUTS
        System.String. Contains the status of whehter the expiration was successful or not.

        .EXAMPLE
        PS> Remove-Token -headers $headers -url $url
    #>
}

function Invoke-CheckIn {
    param (
        [Parameter(Mandatory = $false)] $headers,
        [Parameter(Mandatory = $True)]$url,
        [Parameter(Mandatory = $True)]$SecretId,
        [switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SecretPath = "$Url/api/v1/secrets/$SecretId/check-in"

    $properties = @{
        includeInactive    = $false
        NewPassword        = $null
        DoubleLockPassword = $null
        TicketNumber       = ""
        TicketSystemId     = ""
        Comment            = "SecretCreationScript - Check In"
        forceCheckIn       = $true
    }
    $PasswordChangeArgs = New-Object psObject -Property $properties | ConvertTo-Json
    $params = @{
        Header      = $headers
        Uri         = $SecretPath
        Body        = $PasswordChangeArgs
        ContentType = "application/json"
    }

    try {
        $Secret = Invoke-RestMethod -Method Post @params -UseDefaultCredentials -ErrorAction SilentlyContinue
        return $Secret

    } catch {
        Write-Log $("Secret Check-In Error on ID: $SecretId" + $_)
    }
    <#
        .SYNOPSIS
        Invoke a Check-In action against a specifid SecretID.

        .DESCRIPTION
        This method will check in a secret that has been checked out by another user. The User Performing the check-in must be an "Owner" on the secret, and additioanlly have the "Force Check-In" Role Permissions associated to the user.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SecretID
        SecretID of the secret you'd like to invoke the Check-In against.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Invoke-CheckIn

        .OUTPUTS
        Returns the Status of the Check-In Request.

        .EXAMPLE
        PS> Invoke-CheckIn -headers $headers -url $url -SecretID $SecretId

        .EXAMPLE
        PS> Invoke-CheckIn -useWinAuth -url $url -SecretID $SecretId

    #>
}

function New-Secret {
    param (
        [Parameter(Mandatory = $False)] $headers,
        [Parameter(Mandatory = $True)]$Url,
        [Parameter(Mandatory = $True)]$SecretObject,
        [Parameter(Mandatory = $False)][switch]$UseWinAuth
    )
    #Create the properties for the secret.
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $properties = @{
        "name"                          = $SecretObject.name
        "folderId"                      = $SecretObject.folderId
        "secretTemplateId"              = $SecretObject.SecretTemplateId
        "items"                         = $SecretObject.items
        "launcherConnectAsSecretId"     = $SecretObject.launcherConnectAsSecretId
        "autoChangeEnabled"             = $SecretObject.autoChangeEnabled
        "requiresComment"               = $SecretObject.requiresComment
        "checkOutEnabled"               = $SecretObject.checkOutEnabled
        "checkOutIntervalMinutes"       = $SecretObject.checkOutIntervalMinutes
        "checkOutChangePasswordEnabled" = $SecretObject.checkOutChangePasswordEnabled
        "proxyEnabled"                  = $SecretObject.proxyEnabled
        "sessionRecordingEnabled"       = $SecretObject.sessionRecordingEnabled
        "passwordTypeWebScriptId"       = $SecretObject.passwordTypeWebScriptId
        "siteId"                        = $SecretObject.siteId
        "enableInheritSecretPolicy"     = $SecretObject.enableInheritSecretPolicy
        "secretPolicyId"                = $SecretObject.secretPolicyId
        "sshKeyArgs"                    = $SecretObject.sshKeyArgs
    }

    #Put SecretChangePasswordArgs together, and convert them to JSON to be passed to the API
    $NewSecretArgs = New-Object psObject -Property $properties | ConvertTo-Json

    $params = @{
        Header      = $headers
        Uri         = "$Url/api/v1/secrets"
        body        = $NewSecretArgs
        ContentType = "application/json"
    }
    try {
        if ($UseWinAuth) {
            $NewSecret = Invoke-RestMethod -Method POST @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $newSecret
        } else {
            $NewSecret = Invoke-RestMethod -Method POST @params -ErrorAction SilentlyContinue
            return $newSecret
        }

    } catch {
        throw "Secret Creation Error on: " + $SecretObject.items
        Write-Log $("Secret Creation Error on $SecretObject" + $_)
    }
    <#
        .SYNOPSIS
        Takes in a Secret Stub, or Secret Object and submits that to the SS instance to create a new Secret.

        .DESCRIPTION
        This method provides a mechansim to create new secrets via the API.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SecretObject
        Secret Object with the appropraite parameters created. Either a Secret Stub, or a secret that has been retreived by Get-Secret are appropraite inputs to this method.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to New-Secret.

        .OUTPUTS
        Returns the new secret object.

        .EXAMPLE
        PS> New-Secret -headers $headers -url $url -SecretObject $SecretObject

        .EXAMPLE
        PS> New-Secret -useWinAuth -url $url -SecretObject $SecretObject

    #>
}

function Get-Secret {
    param (
        [Parameter(Mandatory = $false)] $headers,
        [Parameter(Mandatory = $True)]$url,
        [Parameter(Mandatory = $True)]$SecretId,
        [switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SecretPath = "$Url/api/v1/secrets/$SecretId/restricted"

    $properties = @{
        IncludeInactive    = $true
        NewPassword        = $null
        DoubleLockPassword = $null
        TicketNumber       = ""
        TicketSystemId     = ""
        Comment            = "SecretSyncScript"
        ForceCheckIn       = $true
    }
    $SecretRestrictedArgs = New-Object psObject -Property $properties | ConvertTo-Json
    $params = @{
        Header      = $headers
        Uri         = $SecretPath
        Body        = $SecretRestrictedArgs
        ContentType = "application/json"
    }

    try {
        $Secret = Invoke-RestMethod -Method Post @params -UseDefaultCredentials -ErrorAction SilentlyContinue
        return $Secret

    } catch {
        Write-Log $("Secret Creation Error on $SecretObject" + $_)
    }
    <#
        .SYNOPSIS
        Gets full Secret details of a Secret including Secret Field Data.

        .DESCRIPTION
        This method takes in the Secret ID, and returns all data associated with a secret including properties and Secret Fields. This method can be used to return secret field data.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SecretId
        ID of the secret to be returned.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Get-Secret.

        .OUTPUTS
        System.Object. Returns the secret object.

        .EXAMPLE
        PS> Get-Secret -headers $headers -url $url -SecretID "26"

        .EXAMPLE
        PS> Get-Secret -useWinAuth -url $url -SecretID "26"

    #>
}

function Update-Secret {
    param (
        [Parameter(Mandatory = $False)]$headers,
        [Parameter(Mandatory = $True)]$url,
        [Parameter(Mandatory = $True)]$SecretID,
        [Parameter(Mandatory = $True)]$SecretObject,
        [switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SecretPath = "$Url/api/v1/secrets/$SecretId"

    $properties = @{
        "id"                            = $SecretObject.Id
        "name"                          = $SecretObject.name
        "folderId"                      = $SecretObject.folderId
        "active"                        = $SecretObject.active
        "items"                         = $SecretObject.items
        "launcherConnectAsSecretId"     = $SecretObject.launcherConnectAsSecretId
        "autoChangeEnabled"             = $SecretObject.autoChangeEnabled
        "requiresComment"               = $SecretObject.requiresComment
        "checkOutEnabled"               = $SecretObject.checkOutEnabled
        "checkOutIntervalMinutes"       = $SecretObject.checkOutIntervalMinutes
        "checkOutChangePasswordEnabled" = $SecretObject.checkOutChangePasswordEnabled
        "proxyEnabled"                  = $SecretObject.proxyEnabled
        "sessionRecordingEnabled"       = $SecretObject.sessionRecordingEnabled
        "passwordTypeWebScriptId"       = $SecretObject.passwordTypeWebScriptId
        "siteId"                        = $SecretObject.siteId
        "enableInheritPermissions"      = $SecretObject.enableInheritPermissions
        "enableInheritSecretPolicy"     = $SecretObject.enableInheritSecretPolicy
        "secretPolicyId"                = $SecretObject.secretPolicyId
        "autoChangeNextPassword"        = $SecretObject.autoChangeNextPassword
        "sshKeyArgs"                    = $SecretObject.sshKeyArgs
    }

    #Put SecretChangePasswordArgs together, and convert them to JSON to be passed to the API
    $UpdateSecretArgs = New-Object psObject -Property $properties | ConvertTo-Json

    $params = @{
        Header      = $headers
        Uri         = $SecretPath
        body        = $UpdateSecretArgs
        ContentType = "application/json"
    }

    try {
        if ($usewinauth) {
            $UpdateSecret = Invoke-RestMethod -Method PUT @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $UpdateSecret
        } else {
            $UpdateSecret = Invoke-RestMethod -Method PUT @params -ErrorAction SilentlyContinue
            return $UpdateSecret
        }


    } catch {
        Write-Log $("Secret Update Error on $UpdateSecret" + $_)
    }
    <#
        .SYNOPSIS
        Updates a Secret with the passed in Secret value data.

        .DESCRIPTION
        This method takes in the Secret ID, and a Secret Object and updates the Secret with the new information. Getting the Secret using Get-Secret, modifying the data, and re-submitting via Update-Secret will update the values in SS.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SecretId
        ID of the secret to be returned.

        .PARAMETER SecretObject
        Secret Object with the appropraite parameters created. Either a Secret Stub, or a secret that has been retreived by Get-Secret are appropraite inputs to this method.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Update-Secret.

        .OUTPUTS
        System.Object Returns the updated Secret object.

        .EXAMPLE
        PS> Update-Secret -headers $headers -url $url -SecretID "26" -SecretObject $SecretObject

        .EXAMPLE
        PS> Get-Secret -useWinAuth -url $url -SecretID "26" -SecretObject $SecretObject

    #>
}

function Search-Secrets {
    param (
        [Parameter(Mandatory = $false)]$headers,
        [Parameter(Mandatory = $True)] $URL,
        [Parameter(Mandatory = $True)] $SecretName,
        [Parameter(Mandatory = $False)] $FolderId,
        [Parameter(Mandatory = $false)][switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SearchPath = "$Url/api/v1/secrets?take=1000000&filter.searchText=$SecretName&filter.includeRestricted=True&filter.isExactMatch=True"

    if ($FolderId) {
        $SearchPath += "&filter.folderId=$FolderId"
    }

    $params = @{
        Header      = $headers
        Uri         = $SearchPath
        ContentType = "application/json"
    }

    try {
        if ($UseWinAuth) {
            $Secrets = Invoke-RestMethod -Method Get @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $Secrets
        } else {
            $Secrets = Invoke-RestMethod -Method Get @params -ErrorAction SilentlyContinue
            return $Secrets
        }
    } catch {
        Write-Log $("Secret Search Error on $SecretName" + $_)
    }
    <#
        .SYNOPSIS
        Searches secrets the authenticated user has access to and returns them in a tabulated format.

        .DESCRIPTION
        This method takes in a Secret Name, and be further refined by FolderID and will search SS for any secrets matching that Secret Name.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SecretName
        Name of the Secret to be searched for, or general search text that might return any fields that are tagged as "Searchable"

        .PARAMETER FolderID
        ID of the folder you want to restrict your search to.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Search-Secret.

        .OUTPUTS
        System.Object, Paging results of search.

        .EXAMPLE
        PS> Search-Secret -headers $headers -url $url -SecretName "TestSecret"

        .EXAMPLE
        PS> Search-Secret -useWinAuth -url $url -SecretName "TestSecret" -FolderID "7"

    #>
}
function Search-Folders {
    param (
        [Parameter(Mandatory = $False)]$headers,
        [Parameter(Mandatory = $True)]$url,
        [Parameter(Mandatory = $False)]$FolderName,
        [switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $FolderPath = "$Url/api/v1/folders?take=10000&filter.searchText=$FolderName"

    $params = @{
        Header      = $headers
        Uri         = $FolderPath
        ContentType = "application/json"
    }

    try {
        if ($usewinauth) {
            $SearchFolder = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $SearchFolder
        } else {
            $SearchFolder = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
            return $SearchFolder
        }
    } catch {
        Write-Log $("Search Folder Error on $SearchFolder" + $_)
    }
    <#
        .SYNOPSIS
        Searches Folders the authenticated user has access to and returns them in a tabulated format.

        .DESCRIPTION
        This method takes in a Folder Name, and will return any folders that match the name passed in. SS allows for folders with the same name as long as they don't have the same parent folder. Folder Paths are returned from this method, which allows us to map the absolute folder path of an object.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER FolderName
        Name of the Folder to be searched for.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Search-Secret.

        .OUTPUTS
        System.Object, Paging results of search.

        .EXAMPLE
        PS> Search-Folder -headers $headers -url $url -FolderName "TestFolder"

        .EXAMPLE
        PS> Search-Folder -useWinAuth -url $url -FolderName "TestFolder"

    #>
}
function Get-Template {
    param (
        [Parameter(Mandatory = $false)] $headers,
        [Parameter(Mandatory = $True)]$url,
        [Parameter(Mandatory = $True)]$TemplateId,
        [switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SecretPath = "$Url/api/v1/secret-templates/$TemplateId"


    $params = @{
        Header      = $headers
        Uri         = $SecretPath
        ContentType = "application/json"
    }

    try {
        $Template = Invoke-RestMethod -Method Get @params -UseDefaultCredentials -ErrorAction SilentlyContinue
        return $Template

    } catch {
        Write-Log $("Template Retrieval Error on $TemplateID" + $_)
    }
    <#
        .SYNOPSIS
        Returns all the details of a specified Secret Template

        .DESCRIPTION
        This method takes in a Template ID, and returns a custom object containing the details of a given Secret Template. This includes all field information associated with the template.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER TemplateID
        ID of the template to be returned.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Get-Template.

        .OUTPUTS
        System.Object, Template object, containing all properties and items for the field information.

        .EXAMPLE
        PS> Get-Template -headers $headers -url $url -TemplateID "6001"

        .EXAMPLE
        PS> Get-Template -useWinAuth -url $url -TemplateID "6001"

    #>
}

function New-Template {
    param (
        [Parameter(Mandatory = $false)] $headers,
        [Parameter(Mandatory = $True)]$url,
        [Parameter(Mandatory = $True)]$TemplateObject,
        [switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SecretPath = "$Url/api/v1/secret-templates/"
    $properties = @{
        "fields" = $TemplateObject.fields
        "name"   = $TemplateObject.name
    }

    #Put SecretChangePasswordArgs together, and convert them to JSON to be passed to the API
    $TemplateCreateArgs = New-Object psObject -Property $properties | ConvertTo-Json

    $params = @{
        Header      = $headers
        Uri         = $SecretPath
        body        = $TemplateCreateArgs
        ContentType = "application/json"
    }

    try {
        $Template = Invoke-RestMethod -Method POST @params -UseDefaultCredentials -ErrorAction SilentlyContinue
        return $Template

    } catch {
        Write-Log $("Template Creation Error on $TemplateID" + $_)
    }
    <#
        .SYNOPSIS
        Creates a new Secret Template

        .DESCRIPTION
        This method takes in a Template Object, and will create that on the authenticated SS instance. User will require "Administer Secret Templates" Role Permission to run this method. A Template Stub, or a Template from the Get-Template method can be passed into this method to return a valid result.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER TemplateObject
        A Template Object to be created. Either a Template Stub or a Template that has been retrieved via the Template ID can be passed into this method.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to New-Template.

        .OUTPUTS
        System.Object, Template object, containing all properties and items for the field information.

        .EXAMPLE
        PS> New-Template -headers $headers -url $url -TemplateObject $Template

        .EXAMPLE
        PS> New-Template -useWinAuth -url $url -TemplateObject $Template

    #>
}

function Search-Templates {
    param (
        [Parameter(Mandatory = $false)]$headers,
        [Parameter(Mandatory = $True)] $URL,
        [Parameter(Mandatory = $false)] $TemplateName,
        [Parameter(Mandatory = $false)][switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SearchPath = "$Url/api/v1/secret-templates?take=1000000&filter.searchText=$TemplateName"

    $params = @{
        Header      = $headers
        Uri         = $SearchPath
        ContentType = "application/json"
    }

    try {
        if ($UseWinAuth) {
            $Templates = Invoke-RestMethod -Method Get @params -UseDefaultCredentials -ErrorAction SilentlyContinue
            return $Templates
        } else {
            $Templates = Invoke-RestMethod -Method Get @params -ErrorAction SilentlyContinue
            return $Templates
        }
    } catch {
        Write-Log $("Template Search Error on $TemplateName" + $_)
    }
    <#
        .SYNOPSIS
        Searches Secret Templates that exist in the system.

        .DESCRIPTION
        This method searches SS for all templates the authenticated user has access to view. It will return a paging of the template summary. Both the Template name and the ID are contained in this summary.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER TemplateName
        An Optional Parameter to narrow down the search by a "Template Name"

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Search-Template.

        .OUTPUTS
        System.Object, Paging of the Secret Template Summaries, containing a summary of each returned template.

        .EXAMPLE
        PS> Search-Template -headers $headers -url $url

        .EXAMPLE
        PS> Search-Template -headers $headers -url $url -TemplateName "Windows Account"

        .EXAMPLE
        PS> Search-Template -useWinAuth -url $url -TemplateName "Windows Account"

    #>
}
function New-TemplateMap {
    param (
        [Parameter(Mandatory = $True)]$headers,
        [Parameter(Mandatory = $True)] $URL,
        [Parameter(Mandatory = $false)][switch]$ReverseOutput

    )
    try {
        $Templates = Search-Templates -URL $Url -headers $headers
        $TemplateMap = @{}
        foreach ($template in $Templates.records) {
            if (!$ReverseOutput) {
                $TemplateMap.add($Template.id,$template.name)
            } else {
                $TemplateMap.add($template.name,$Template.id)
            }
        }
        return $TemplateMap
    } catch {
        Throw "Error Encountered Generating Template Map: " + $_
    }
    <#
        .SYNOPSIS
        Maps Secret Templates returned via Search-Templates, and maps them into a hash table.

        .DESCRIPTION
        This method pulls all available templates from a given Secret Server instance. It then parses those into a Hash Table, with the ID being the reference Key. If the -ReverseOutput flag is specified, it will instead use the Template Name as the key. This allows us to quickly map ID's to Template Names between two SS intances.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .INPUTS
        None. You cannot pipe objects to New-TemplateMap.

        .OUTPUTS
        System.Collections.Hashtable, Mapping either ID's to Template Names, or Template Names to ID's

        .EXAMPLE
        PS> New-TemplateMap -headers $SourceHeaders -url $SourceUrl

        .EXAMPLE
        PS> New-TemplateMap -headers $TargetHeaders -url $TargetUrl -ReverseOutput

    #>
}
function Get-SecretStub {
    param (
        [Parameter(Mandatory = $False)] $headers,
        [Parameter(Mandatory = $True)] $url,
        [Parameter(Mandatory = $True)]$SecretTemplateId,
        [Parameter(Mandatory = $True)]$FolderID,
        [Parameter(Mandatory = $False)][switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SecretPath = "$Url/api/v1/secrets/stub?SecretTemplateID=$SecretTemplateID&FolderID=$FolderID"

    $params = @{
        Header      = $headers
        Uri         = $SecretPath
        Body        = $SecretStubArgs
        ContentType = "application/json"
    }

    try {
        $SecretStub = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
        return $SecretStub

    } catch {
        Write-Log $("Secret Creation Error on $SecretObject" + $_)
    }
    <#
        .SYNOPSIS
        Gets a Secret Stub based on Template and Folder settings.

        .DESCRIPTION
        This method provides a Secret Stub based on the Template and Folder Specified. It will prepopulate the secret fields for data to be placed into.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SecretTemplateId
        ID of the Secret Template to be leveraged for the Secret Stub.

        .PARAMETER FolderID
        The ID of the Folder this Secret will be placed into.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Get-SecretStub.

        .OUTPUTS
        System.Object Returns the updated Secret object.

        .EXAMPLE
        PS> Get-SecretStub -headers $headers -url $url -SecretID "26" -SecretObject $SecretObject

        .EXAMPLE
        PS> Get-Secret -useWinAuth -url $url -SecretID "26" -SecretObject $SecretObject

    #>
}
function Get-SecretField {
    param (
        [Parameter(Mandatory = $false)] $headers,
        [Parameter(Mandatory = $True)]$url,
        [Parameter(Mandatory = $True)]$SecretId,
        [Parameter(Mandatory = $True)]$slug,
        [switch]$UseWinAuth
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SecretPath = "$Url/api/v1/secrets/$SecretId/fields/$slug"

    $params = @{
        Header      = $headers
        Uri         = $SecretPath
        ContentType = "application/json"
    }

    try {
        $SecretField = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
        return $SecretField

    } catch {
        Write-Log $("Secret Field Retrieval Error on $SecretID" + $_)
    }
    <#
        .SYNOPSIS
        Gets a Specific Secret Field, primarily used for downloading files.

        .DESCRIPTION
        This method returns a specific field from a given secret. This endpoint will download files that are attached to secret fields as binary output or string data.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SecretID
        ID of the Secret to retrieve the field from.

        .PARAMETER slug
        The Slug of the field to be retrieved.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Get-SecretField.

        .OUTPUTS
        System.Object Returns the Secret field Data, or the Binary of the file attached.

        .EXAMPLE
        PS> Get-SecretField -headers $headers -url $url -SecretID "26" -slug "FileField"

        .EXAMPLE
        PS> Get-SecretField -useWinAuth -url $url -SecretID "26" -slug "FileField"

    #>
}

function Update-SecretField {
    param (
        [Parameter(Mandatory = $false)] $headers,
        [Parameter(Mandatory = $True)]$url,
        [Parameter(Mandatory = $True)]$SecretId,
        [Parameter(Mandatory = $True)]$slug,
        [Parameter(Mandatory = $True)]$fileName,
        [Parameter(Mandatory = $True)]$FileAttachment
    )
    if ($UseWinAuth) { $url += "/winauthwebservices" }
    $SecretPath = "$Url/api/v1/secrets/$SecretId/fields/$slug"

    $properties = @{
        comment            = "Secret Sync Script"
        doubleLockPassword = $null
        fileAttachment     = $FileAttachment
        fileName           = $fileName
        forceCheckIn       = $true
        IncludeInactive    = $true
    }
    $SecretRestrictedArgs = New-Object psObject -Property $properties | ConvertTo-Json
    $params = @{
        Header      = $headers
        Uri         = $SecretPath
        Body        = $SecretRestrictedArgs
        ContentType = "application/json"
    }

    try {
        $Secret = Invoke-RestMethod -Method PUT @params -UseDefaultCredentials -ErrorAction SilentlyContinue
        return $Secret

    } catch {
        Write-Log $("Secret Field update Error on $SecretID" + $_)
    }
    <#
        .SYNOPSIS
        Updates a Specific Secret Field, primarily used for uploading files.

        .DESCRIPTION
        This method updates a specific field from a given secret. This endpoint will upload files that are attached to secret fields as binary input.

        .PARAMETER Headers
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER Url
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SecretID
        ID of the Secret to retrieve the field from.

        .PARAMETER slug
        The Slug of the field to be retrieved.

        .PARAMETER fileName
        The Name of the file being uploaded to the secret field in Secret Server.

        .PARAMETER FileAttachment
        The Binary formatted file attachment to be uploaded.

        .PARAMETER UseWinAuth
        If SS On-Premises is configured for IWA for the API, this switch can be used as an alternate authentication mechanism. If WinAuth is used, headers are not required.

        .INPUTS
        None. You cannot pipe objects to Update-SecretField.

        .OUTPUTS
        System.Object Returns the Secret field upload status.

        .EXAMPLE
        PS> Update-SecretField -headers $headers -url $url -SecretID "26" -slug "FileField" -fileName "PrivateKey.key" -FileAttachment $BinaryData

    #>
}
function Set-SecretProperties {
    param(
        [Parameter(Mandatory = $true)]$SourceSecretObj,
        [Parameter(Mandatory = $true)]$TargetSecretObj
    )
    $TemplateDiff = Compare-Object -ReferenceObject $TargetSecretObj.items.fieldName -DifferenceObject $SourceSecretObj.items.fieldName
    foreach ($SourceItem in $SourceSecretObj.items) {
        if ($templateDiff.InputObject -contains $sourceItem.fieldname) {
            $notes += "`r`n" + $SourceItem.Fieldname + ": " + $sourceItem.itemvalue
            continue
        }
        foreach ($TargetItem in $TargetSecretObj.items) {
            if ($SourceItem.fieldName -eq $targetitem.fieldname) {
                $TargetItem.itemValue = $SourceItem.itemvalue
                break
            }

        }
    }
    if ($TemplateDiff) {
        $($TargetSecretObj.items | Where-Object -Property "FieldName" -Like "Notes").itemvalue += $notes
    }
    <#
        .SYNOPSIS
        Sets the Secret Field properites from one Secret to another.

        .DESCRIPTION
        Sets the Secret Field properites from one Secret to another. If there is a field in the source that does not exist in the destination it will append those fields into the notes.

        .PARAMETER SourceSecretObj
        Source Secret Object you to get the properties from.

        .PARAMETER TargetSecretObj
        Target Secret Object Properties will be set on.

        .INPUTS
        None. You cannot pipe objects to Set-SecretProperties.

        .OUTPUTS
        System.Object Returns the Secret field upload status.

        .EXAMPLE
        PS> Set-SecretProperties -SourceSecretObj $SourceSecret -TargetSecretObj $TargetSecret

    #>
}
function Set-FileFields {
    param(
        [Parameter(Mandatory = $true)]$SourceHeaders,
        [Parameter(Mandatory = $true)]$TargetHeaders,
        [Parameter(Mandatory = $true)]$SourceInstance,
        [Parameter(Mandatory = $true)]$TargetInstance,
        [Parameter(Mandatory = $true)]$SourceSecretObj,
        [Parameter(Mandatory = $true)]$TargetSecretObj
    )
    try {
        foreach ($SourceItem in $SourceSecretObj.items) {
            if ($sourceitem.isfile -and $sourceitem.filename) {
                foreach ($TargetItem in $TargetSecretObj.items) {
                    if ($SourceItem.fieldName -eq $targetitem.fieldname) {
                        $Sourcefile = Get-SecretField -url $SourceInstance -headers $SourceHeaders -SecretId $SourceSecretObj.id -slug $sourceitem.slug
                        if ($($sourceFile.getType()).name -like "String") {
                            $binaryFile = [System.Text.Encoding]::UTF8.GetBytes($SourceFile)
                            $updatefield = Update-SecretField -headers $TargetHeaders -url $targetInstance -secretId $TargetSecretObj.id -slug $TargetItem.slug -filename $SourceItem.fileName -fileAttachment $binaryFile
                        } else {
                            $updatefield = Update-SecretField -headers $TargetHeaders -url $targetInstance -secretId $TargetSecretObj.id -slug $TargetItem.slug -filename $SourceItem.fileName -fileAttachment $SourceFile
                        }
                        break
                    }
                }
            }
        }
        return $true
    } catch {
        Write-log $("Unable to Sync Files: " + $_)
    }
    <#
        .SYNOPSIS
        Sets the Secret File Field properites from one Secret to another.

        .DESCRIPTION
        Iterates through fields on matching secrets and will upload any files from the source to the target.

        .PARAMETER SourceHeaders
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER TargetHeaders
        Headers that have been formatted for API access. Use Get-Token to return appropraite OAUTH Headers.

        .PARAMETER SourceInstance
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER TargetInstance
        Specifies the base path to your Secret Server Instance. Example: "https://secretserverurl.com/secretserver"

        .PARAMETER SourceSecretObj
        Source Secret Object you to get the files from.

        .PARAMETER TargetSecretObj
        Target Secret Object files will be set on.

        .INPUTS
        None. You cannot pipe objects to Set-FileFields.

        .OUTPUTS
        System.Boolean, returns true if files transfer successfully.

        .EXAMPLE
        PS> Set-FileFields -sourceheaders $sourceheaders -targetheaders $targetheaders -sourceinstance $SourceInstance -targetinstance $targetInstance -sourcesecretobj $SourceSecret -TargetSecretObj $TargetSecret

    #>
}


#Logic starts here
#Compile Arguments for Each Instance
#Get Secret in question for Source Instance
#Check and see if the secret exists in the target system
#If the secret does exist, compare the two, if they are the same, then all good
#If Secret Does exist, and items are different, update items
#If item doens't exist create new

function Invoke-SecretSync {
    param(
        [Parameter(Mandatory = $true)]$SourceInstance,
        [Parameter(Mandatory = $true)]$TargetInstance,
        [Parameter(Mandatory = $true)]$SecretID,
        [Parameter(Mandatory = $true)]$Username,
        [Parameter(Mandatory = $true)]$Password,
        [Parameter(Mandatory = $true)]$SourceFolderName,
        [Parameter(Mandatory = $true)]$SourceFolderPath
    )

    Try {
        $SourceHeaders = Get-Token -url $SourceInstance -username $username -password $password
        $TargetHeaders = Get-Token -url $TargetInstance -username $username -password $password
        $SourceTemplateMap = New-TemplateMap -headers $sourceheaders -url $SourceInstance
        $TargetTemplateMap = New-TemplateMap -headers $Targetheaders -url $TargetInstance -ReverseOutput
        #Validate Target Folder Exists, if it doesn't, create it.
        $TargetFolders = Search-Folders -headers $TargetHeaders -url $TargetInstance -FolderName $SourceFolderName
        foreach ($folder in $TargetFolders.records) {
            if ($folder.folderpath -eq $SourceFolderPath) {
                $TargetFolderID = $folder.id
            }
        }
        $SourceSecret = Get-Secret -headers $SourceHeaders -url $SourceInstance -SecretID $SecretID
        if (!$SourceSecret) {
            $null = Invoke-CheckIn -headers $SourceHeaders -url $SourceInstance -SecretId $SecretID
            $SourceSecret = Get-Secret -headers $SourceHeaders -url $SourceInstance -SecretID $SecretID
            $null = Invoke-CheckIn -headers $SourceHeaders -url $SourceInstance -SecretId $SecretID
        }
        $TargetSecretName = ($SourceSecret.id).ToString() + "-" + $SourceSecret.name
        #Check to see if the secret already exists in the destination, if not, Create It
        $TargetSecretSearch = Search-Secrets -headers $TargetHeaders -URL $TargetInstance -SecretName $TargetSecretName
        if ($TargetSecretSearch.Records.count -eq 0) {
            if ($null -eq $TargetTemplateMap[$SourceTemplateMap[$SourceSecret.secretTemplateId]]) {
                $template = Get-Template -headers $SourceHeaders -url $SourceInstance -templateID $SourceSecret.secretTemplateId
                $newTemplate = New-Template -headers $TargetHeaders -url $TargetInstance -TemplateObject $template
                $stub = Get-SecretStub -headers $TargetHeaders -url $TargetInstance -SecretTemplateId $newTemplate.id -FolderID $TargetFolderID
            } else {
                $stub = Get-SecretStub -headers $TargetHeaders -url $TargetInstance -SecretTemplateId $TargetTemplateMap[$SourceTemplateMap[$SourceSecret.secretTemplateId]] -FolderID $TargetFolderID
            }
            $stub.name = $TargetSecretName
            $stub.siteId = 1
            $null = Set-SecretProperties -SourceSecretObj $SourceSecret -TargetSecretObj $stub
            $NewSecret = New-Secret -headers $TargetHeaders -Url $TargetInstance -SecretObject $stub
            if ($SourceSecret.items.isfile -like $true) {
                $null = Set-FileFields -sourceheaders $sourceheaders -targetheaders $targetheaders -sourceinstance $SourceInstance -targetinstance $targetInstance -sourcesecretobj $SourceSecret -TargetSecretObj $newSecret
            }
            Write-Log $("New Secret Created: " + $NewSecret.name)
        }
        #If Secret Does exist, Update it:
        elseif ($TargetSecretSearch.Records.count -eq 1) {
            $TargetSecret = Get-Secret -headers $TargetHeaders -url $TargetInstance -SecretId $TargetSecretSearch.records.id
            $null = Set-SecretProperties -SourceSecretObj $SourceSecret -TargetSecretObj $TargetSecret
            $null = Update-Secret -url $TargetInstance -headers $Targetheaders -SecretID $TargetSecret.id -SecretObject $TargetSecret
            if ($SourceSecret.items.isfile -like $true) {
                $null = Set-FileFields -sourceheaders $sourceheaders -targetheaders $targetheaders -sourceinstance $SourceInstance -targetinstance $targetInstance -sourcesecretobj $SourceSecret -TargetSecretObj $TargetSecret
            }
            Write-Log $("Secret $TargetSecretName Updated")
        } elseif ($TargetSecretSearch.Records.count -gt 1) {
            $SecretIDMap = [System.Collections.ArrayList]@()
            foreach ($record in $targetsecretsearch.records) {
                $null = $SecretIDMap.add($record.id)
            }
            $SecretIDMap = $SecretIDMap | Sort-Object -Descending
            $TargetSecret = Get-Secret -headers $TargetHeaders -url $TargetInstance -SecretId $SecretIDMap[0]
            $null = Set-SecretProperties -SourceSecretObj $SourceSecret -TargetSecretObj $TargetSecret
            $null = Update-Secret -url $TargetInstance -headers $Targetheaders -SecretID $TargetSecret.id -SecretObject $TargetSecret
            if ($SourceSecret.items.isfile -like $true) {
                $null = Set-FileFields -sourceheaders $sourceheaders -targetheaders $targetheaders -sourceinstance $SourceInstance -targetinstance $targetInstance -sourcesecretobj $SourceSecret -TargetSecretObj $TargetSecret
            }
            Write-Log $("Secret $TargetSecretName Updated")
        }
        #Remove Tokens
        $null = Remove-Token -headers $Sourceheaders -url $SourceInstance
        $null = Remove-Token -headers $TargetHeaders -url $TargetInstance
    } catch {

        if ($sourceheaders) { $null = Remove-Token -headers $Sourceheaders -url $SourceInstance }
        if ($targetheaders) { $null = Remove-Token -headers $TargetHeaders -url $TargetInstance }
        throw "Error Encountered Syncing Secret: " + $_
    }

}
#Arguments: $[ADD:1]$URL $[ADD:1]$URL2 $SecretID $[ADD:1]$USERNAME $[ADD:1]$PASSWORD $FolderName $FolderPath
Invoke-SecretSync -SourceInstance $args[0] -TargetInstance $args[1] -SecretID $args[2] -Username $args[3] -Password $args[4] -SourceFolderName $args[5] -SourceFolderPath $args[6]


