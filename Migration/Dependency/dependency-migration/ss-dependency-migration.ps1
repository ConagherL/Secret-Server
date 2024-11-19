$sourceUrl = 'https://'
$targeturl = 'https://'
$logPath = 'c:\migration\ssDependencyMigration.log'

function Get-Token {
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $True, Position = 0)]
        $WebProxy,
        [Parameter(Mandatory = $False)]
        $Username,
        [Parameter(Mandatory = $False)]
        $Password,
        [Parameter(Mandatory = $False)]
        $Domain,
        [Parameter(Mandatory = $False)]
        $OrgCode,
        [Parameter(Mandatory = $False)]
        $MFAToken

    )
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    #Enter HardCoded Credentials, or use Get-Credential Method to input username and password.

    if (!$username -or !$password) {
        $AuthToken = Get-Credential
        $username = $AuthToken.UserName
        $password = $AuthToken.GetNetworkCredential().Password
    }

    # Define the user credentials
    # $username = ""
    # $password = ""
    if (!$OrgCode) {
        $OrgCode = ''
    }
    if (!$Domain) {
        $Domain = 'local'
    }
    if (!$MFAToken) {
        $tokenResult = $WebProxy.Authenticate($username, $password, $OrgCode, $domain)
        if ($tokenResult.Errors.Count -gt 0) {
            Write-Output 'Authentication Error: ' + $tokenResult.Errors[0]
            Return
        }
    } else {
        $tokenResult = $WebProxy.Authenticate($username, $password, $OrgCode, $domain, $MFAToken)
        if ($tokenResult.Errors.Count -gt 0) {
            Write-Output 'Authentication Error: ' + $tokenResult.Errors[0]
            Return
        }
    }
    $token = $tokenResult.Token

    return $token

}
function Get-Headers {
    param (
        [Parameter(Mandatory = $True)]$URL,
        [Parameter(Mandatory = $False)]$username,
        [Parameter(Mandatory = $false)]$password,
        [switch]$ReturnToken
    )

    if (!$username -or !$password) {
        $AuthToken = Get-Credential
        $username = $AuthToken.UserName
        $password = $AuthToken.GetNetworkCredential().Password
    }
    $creds = @{
        username   = $UserName
        password   = $Password
        grant_type = 'password'
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

        throw 'Authentication Error' + $_
    }

}
function Get-Sites {
    param (
        [Parameter(Mandatory = $False)]$headers,
        [Parameter(Mandatory = $True)]$url,
        [switch]$ReturnTable,
        [switch]$ReverseOutput
    )
    if ($UseWinAuth) { $url += '/winauthwebservices' }
    $Path = "$Url/api/v1/distributed-engine/sites"

    $params = @{
        Header      = $headers
        Uri         = $Path
        ContentType = 'application/json'
    }
    try {
        if ($returnTable) {
            $Sites = Invoke-RestMethod -Method Get @params -ErrorAction SilentlyContinue
            $SiteTableMap = @{}
            foreach ($record in $Sites.records) {
                if ($reverseOutput) {
                    $SiteTableMap[$record.siteName] = $record.siteId
                } else {
                    $SiteTableMap[$record.siteId] = $record.siteName
                }
            }
            return $SiteTableMap
        } else {
            $sites = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
            return $sites
        }

    } catch {
        Write-Log $("Error Getting Sites: $sites" + $_)
        throw "Error Getting Sites:  $sites" + $_
    }
}
function Get-SecretDependencyTemplates {
    param (
        [Parameter(Mandatory = $False)]$headers,
        [Parameter(Mandatory = $True)]$url,
        [switch]$ReturnTable,
        [switch]$ReverseOutput
    )
    $Path = "$Url/api/v1/secret-dependencies/templates"

    $params = @{
        Header      = $headers
        Uri         = $Path
        ContentType = 'application/json'
    }
    try {
        if ($returnTable) {
            $DependencyTemplates = Invoke-RestMethod -Method Get @params -ErrorAction SilentlyContinue
            $DependencyTemplatesMap = @{}
            foreach ($record in $DependencyTemplates.model) {
                if ($reverseOutput) {
                    $DependencyTemplatesMap[$record.name] = $record.Id
                } else {
                    $DependencyTemplatesMap[$record.Id] = $record.Name
                }
            }
            return $DependencyTemplatesMap
        } else {
            $DependencyTemplates = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
            return $DependencyTemplates
        }
    } catch {
        Write-Log $("Error Getting DependencyTemplates: $DependencyTemplates" + $_)
        throw "Error Getting DependencyTemplates:  $DependencyTemplates" + $_
    }
}
function Get-DependencyScripts {
    param (
        [Parameter(Mandatory = $False)]$headers,
        [Parameter(Mandatory = $True)]$url,
        [switch]$ReturnTable,
        [switch]$ReverseOutput
    )
    if ($UseWinAuth) { $url += '/winauthwebservices' }
    $Path = "$Url/api/v1/secret-dependencies/scripts"

    $params = @{
        Header      = $headers
        Uri         = $Path
        ContentType = 'application/json'
    }
    try {
        if ($returnTable) {
            $Scripts = Invoke-RestMethod -Method Get @params -ErrorAction SilentlyContinue
            $ScriptTableMap = @{}
            foreach ($record in $Scripts.model) {
                if ($reverseOutput) {
                    $ScriptTableMap[$record.Name] = $record.Id
                } else {
                    $ScriptTableMap[$record.Id] = $record.Name
                }
            }
            return $ScriptTableMap
        } else {
            $Scripts = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
            return $Scripts
        }
    } catch {
        Write-Log $("Error Getting Dependency Scripts: $Scripts" + $_)
        throw "Error Getting Dependency Scripts:  $Scripts" + $_
    }
}
function Invoke-DependencyMigration {
    <#
   .Synopsis
    This is a Powershell script to migrate Secret Server files from one instance, to a replicated / migrated Target instance.

   .Description
    This script needs to have a mirrored folder / secret structure between the source and Target instance to work properly. Each File Field on the the template will need to have a unique name.

   .Example
    Invoke-FileMigration -SourceUrl https://SourceUrl/secretserver -TargetUrl https://TargetUrl/secretserver

    .Example
    Invoke-FileMigration -SourceUrl https://SourceUrl/secretserver -TargetUrl https://TargetUrl/secretserver -domain testdomain.com -IncludePersonalFolders $false

   .Parameter SourceUrl
    The path to the source instance of Secret Server. This should match your source instance of Secret Server's Base URL and should not contain a trailing "/": Exmaple https://SourceSecretServerURL.com/SecretServer, if you Secret Server is installed at the IIS Root, your url will be: https://SourceSecretServerURL.com

   .Parameter TargetUrl
    The path to the Target instance of Secret Server. This should match your Target instance of Secret Server's Base URL and should not contain a trailing "/": Exmaple https://TargetSecretServerURL.com/SecretServer, if you Secret Server is installed at the IIS Root, your url will be: https://TargetSecretServerURL.com

    .Parameter OrgCode
    If you are connecting to a legacy instance of Secret Server Online (SSO), you will need to provide an OrgCode as a parameter to authenticate.

    .Parameter Domain
    If you are using a Domain User to authenticate and migrate the files, please enter the Domain value that is used to log in. Example: example.com

    .Parameter MFAToken
    If two-factor authentication is enabled, our API's support any authentication that can provide a code before the initial access challenge.

    .Parameter ConcurrentJobs
    Default is 8, this will control the number of jobs that the script will create at one time, this can be throttled for performance.

    .Parameter IncludePersonalFolders
    Default is $true, this will include the personal folders in the migration path, if you do not wish to include personal folders, set this value to false.

    .Parameter Log
    Text file that will contain all outputs from this script, all successful and failed migration items will be logged here. By default C:\SSMigrationLog.txt

   .Inputs
    [System.String]

   .Notes
    NAME:  Invoke-FileMigration
    AUTHOR: Andy Crandall
    LASTEDIT: 10/09/2018 14:21:22

   .Link
    https://thycotic.github.com

 #Requires -Version 3.0
 #>
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory = $False)]
        [string]$SourceUrl,
        [Parameter(Mandatory = $False)]
        [string]$TargetUrl,
        [Parameter(Mandatory = $False)]
        [string]$OrgCode = '',
        [Parameter(Mandatory = $False)]
        [string]$Domain = 'local',
        [Parameter(Mandatory = $False)]
        [string]$MFAToken,
        [Parameter(Mandatory = $False)]
        [int]$ConcurrentJobs = '7',
        [Parameter(Mandatory = $False)]
        [bool]$IncludePersonalFolders = $true,
        [parameter(Mandatory = $False)]
        [string]$Log = 'C:\Migration\SSDependencyMigrationLog.txt'
    )
    # Initialize Variables, and Create Hash Tables for comparison, as well as for verifying ParentFolderID.
    #------------------------------------
    Write-Host 'Beginning Script, initializing variables and creating reference tables.'
    $stopwatch = [system.diagnostics.stopwatch]::StartNew()
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $elapsed = $Stopwatch.Start()
    $MigratedSuccessfully = @()
    $NoMatches = @()
    $UnMatchedFields = @()

    if (!$SourceUrl) {
        $SourceUrl = Read-Host 'Please Enter the Source Instance URL, for example: https://SourceSecretServerURL.com/SecretServer'
    }
    if (!$TargetUrl) {
        $TargetUrl = Read-Host 'Please Enter the Source Instance URL, for example: https://TargetSecretServerURL.com/SecretServer'
    }

    $SourceFolderReference = @{}
    $TargetFolderReference = @{}
    $FolderMap = @{}

    $SourceSOAPUrl = "$SourceUrl/webservices/SSWebservice.asmx?wsdl"
    $TargetSOAPUrl = "$TargetUrl/webservices/SSWebservice.asmx?wsdl"
    $SourceProxy = New-WebServiceProxy -uri $SourceSOAPUrl -UseDefaultCredential -Namespace 'ss'
    $TargetProxy = New-WebServiceProxy -uri $TargetSOAPUrl -UseDefaultCredential -Namespace 'ss'

    Write-Host 'Generating Source Access Token'
    $sourceAuthToken = Get-Credential
    $SourceUsername = $sourceAuthToken.UserName
    $SourcePassword = $sourceAuthToken.GetNetworkCredential().Password
    $SourceToken = Get-Token -WebProxy $SourceProxy -username $sourceusername -password $sourcePassword
    $SourceHeaders = Get-Headers -url $SourceUrl -username $sourceusername -password $sourcePassword

    Write-Host 'Generating Target Access Token'
    $targetAuthToken = Get-Credential
    $TargetUsername = $targetAuthToken.UserName
    $TargetPassword = $targetAuthToken.GetNetworkCredential().Password
    $TargetToken = Get-Token -WebProxy $TargetProxy -username $Targetusername -password $TargetPassword
    $TargetHeaders = Get-Headers -url $TargetUrl -username $Targetusername -password $TargetPassword

    $SourceFolders = $SourceProxy.SearchFolders($SourceToken, '')
    $TargetFolders = $TargetProxy.SearchFolders($TargetToken, '')

    #Build Hash Tabled References for organization.
    foreach ($folder in $SourceFolders.Folders) {
        $FolderName = $folder.Name
        $FolderID = $folder.ID
        $ParentFolderID = $folder.ParentFolderID
        $SourceFolderReference[$FolderID] = ($FolderName, $ParentFolderID)
    }

    foreach ($folder in $TargetFolders.Folders) {
        $FolderName = $folder.Name
        $FolderID = $folder.ID
        $ParentFolderID = $folder.ParentFolderID
        $TargetFolderReference[$FolderID] = ($FolderName, $ParentFolderID)
    }
    $personalfolderID = 0
    foreach ($key in $SourceFolderReference.keys) {
        if ($SourceFolderReference[$key].item(0) -eq 'Personal Folders') {
            $personalfolderID = $key
        }
    }

    #Run through and build a list of corresponding Folder ID's between the two environments,
    # using the reference hash tables above, to ensure each folder returned has the same Parent Folder.
    # Duplicate Folder Names are not allowed at the same level.
    $elapsed = $Stopwatch.Elapsed
    Write-Host "Building folder mappings between instances. Elapsed Time: $elapsed"
    foreach ($folder in $SourceFolders.Folders) {
        $TargetFolderID = $null
        $SourceFolderID = $folder.Id
        $SourceFolderName = $folder.name
        $SourceParentFolderId = $SourceFolderReference[$SourceFolderID].item(1)

        if ($IncludePersonalFolders -eq $False) {
            if ($SourceParentFolderId -ne $personalfolderID) {
                #if the source parent folder, is not a top level folder, create the reference of parent folders.
                if ($SourceParentFolderId -ne '-1') {
                    # $SourceParentFolderName = $SourceFolderReference[$SourceParentFolderId].item(0)
                    $SourceParentReference = @()
                    $ReferenceFolderID = $SourceParentFolderId
                    #build the source folder path once, to reduce script iterations.
                    while ($ReferenceFolderID -ne '-1') {
                        $SourceParentReference += $SourceFolderReference[$ReferenceFolderID].item(0)
                        $ReferenceFolderID = $SourceFolderReference[$ReferenceFolderID].item(1)
                    }
                    [array]::Reverse($SourceParentReference)
                    $SourceFolderPath = $SourceParentReference -join '/'
                }
                #Folders can be duplicated as long as they are not on the same Level, so we check to verify that the Parent Folder ID is the same.
                foreach ($key in $TargetFolderReference.Keys) {
                    $TargetFolderName = $TargetFolderReference[$key].item(0)
                    $TargetParentFolderID = $TargetFolderReference[$key].item(1)

                    #If the folder is a top level folder, and the names match, add this to our Mapping Array.
                    if ($SourceParentFolderId -eq '-1' -and $TargetParentFolderID -eq '-1' -and $SourceFolderName -eq $TargetFolderName) {
                        $TargetFolderID = $key
                        $FolderMap.Add($SourceFolderID, $TargetFolderID)
                        Break
                    }
                    #If the Folder is not top level, compare to see if the parent folders are the same, if they are and the name matches then its the corresponding folder.
                    elseif ($SourceParentFolderID -ne '-1' -and $TargetParentFolderID -ne '-1') {
                        #Creating an array of all the parent folders into an array so we can compare the actual folder-path.
                        $TargetParentReference = @()
                        $ReferenceFolderID = $TargetParentFolderID
                        while ($ReferenceFolderID -ne '-1') {
                            $TargetParentReference += $TargetFolderReference[$ReferenceFolderID].item(0)
                            $ReferenceFolderID = $TargetFolderReference[$ReferenceFolderID].item(1)
                        }
                        [array]::Reverse($TargetParentReference)
                        $TargetFolderPath = $TargetParentReference -join '/'

                        $compare = $SourceFolderPath -eq $TargetFolderPath
                        if ($compare -eq $true -and $SourceFolderName -eq $TargetFolderName) {
                            $TargetFolderID = $key
                            $FolderMap.Add($SourceFolderID, $TargetFolderID)
                            Break
                        }
                    }
                }
            }
        } else {
            #if the source parent folder, is not a top level folder, create the reference of parent folders.
            if ($SourceParentFolderId -ne '-1') {
                # $SourceParentFolderName = $SourceFolderReference[$SourceParentFolderId].item(0)
                $SourceParentReference = @()
                $ReferenceFolderID = $SourceParentFolderId
                while ($ReferenceFolderID -ne '-1') {
                    $SourceParentReference += $SourceFolderReference[$ReferenceFolderID].item(0)
                    $ReferenceFolderID = $SourceFolderReference[$ReferenceFolderID].item(1)
                }
                [array]::Reverse($SourceParentReference)
                $SourceFolderPath = $SourceParentReference -join '/'
            }
            #Folders can be duplicated as long as they are not on the same Level, so we check to verify that the Parent Folder ID is the same.
            foreach ($key in $TargetFolderReference.Keys) {
                $TargetFolderName = $TargetFolderReference[$key].item(0)
                $TargetParentFolderID = $TargetFolderReference[$key].item(1)

                #If the folder is a top level folder, and the names match, add this to our Mapping Array.
                if ($SourceParentFolderId -eq '-1' -and $TargetParentFolderID -eq '-1' -and $SourceFolderName -eq $TargetFolderName) {
                    $TargetFolderID = $key
                    $FolderMap.Add($SourceFolderID, $TargetFolderID)
                    Break
                }
                #If the Folder is not top level, compare to see if the parent folders are the same, if they are and the name matches then its the corresponding folder.
                elseif ($SourceParentFolderID -ne '-1' -and $TargetParentFolderID -ne '-1') {
                    #Creating an array of all the parent folders into an array so we can compare the actual folder-path.
                    $TargetParentReference = @()
                    $ReferenceFolderID = $TargetParentFolderID
                    while ($ReferenceFolderID -ne '-1') {
                        $TargetParentReference += $TargetFolderReference[$ReferenceFolderID].item(0)
                        $ReferenceFolderID = $TargetFolderReference[$ReferenceFolderID].item(1)
                    }
                    [array]::Reverse($TargetParentReference)
                    $TargetFolderPath = $TargetParentReference -join '/'
                    $compare = $SourceFolderPath -eq $TargetFolderPath

                    if ($compare -eq $true -and $SourceFolderName -eq $TargetFolderName) {
                        $TargetFolderID = $key
                        $FolderMap.Add($SourceFolderID, $TargetFolderID)
                        Break
                    }
                }
            }
        }
    }

    $elapsed = $Stopwatch.Elapsed
    Write-Host "Finished building FolderMappings. Elapsed time: $elapsed"

    #Threading Section -------------------------------------------------------------------
    Write-Host 'Creating Threads to Migrate Files between Folders'

    #Specify Code to be run for each Job.
    $CodeContainer = {
        Param(
            $SourceUrl,
            $TargetUrl,
            $SourceToken,
            $TargetToken,
            $SourceFolderID,
            $TargetFolderID,
            $Log,
            $SourceFolderName,
            $SourceHeaders,
            $TargetHeaders,
            $SourceScripts,
            $TargetScripts,
            $SourceDependencyTemplatesMap,
            $TargetDependencyTemplatesMap,
            $SourceSites,
            $TargetSites
        )
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        function Write-Log {
            param (
                [Parameter(Mandatory = $True, ValueFromPipeline = $True)] $logItem
            )
            [string]$TimeStamp = Get-Date
            $LogPath = $log
            "[$TimeStamp]: " + $logitem | Out-File -FilePath $LogPath -Append
        }
        function Search-Secret {
            param (
                [Parameter(Mandatory = $false)]$headers,
                [Parameter(Mandatory = $True)] $URL,
                [Parameter(Mandatory = $True)] $SecretName,
                [Parameter(Mandatory = $false)][switch]$UseWinAuth
            )
            if ($UseWinAuth) { $url += '/winauthwebservices' }
            $SearchPath = "$Url/api/v1/secrets?take=1000000&filter.searchText=$SecretName&filter.includeRestricted=True"
            $params = @{
                Header      = $headers
                Uri         = $SearchPath
                ContentType = 'application/json'
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
        }
        function Get-SecretDependencies {
            param (
                [Parameter(Mandatory = $False)]$headers,
                [Parameter(Mandatory = $True)]$url,
                [Parameter(Mandatory = $True)]$SecretID,
                [switch]$UseWinAuth
            )
            if ($UseWinAuth) { $url += '/winauthwebservices' }
            $Path = "$Url/api/v1/secret-dependencies?take=100000"
            if ($SecretID) { $Path += "&filter.secretId=$SecretID" }
            $params = @{
                Header      = $headers
                Uri         = $Path
                ContentType = 'application/json'
            }
            try {
                if ($usewinauth) {
                    $Dependency = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                    return $Dependency
                } else {
                    $Dependency = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
                    return $Dependency
                }
            } catch {
                Write-Log $("Error Searching for Dependencies: $Dependency" + $_)
                throw "Error Searching for Dependencies: $Dependency" + $_
            }
        }
        function Get-Dependency {
            param (
                [Parameter(Mandatory = $False)]$headers,
                [Parameter(Mandatory = $True)]$url,
                [Parameter(Mandatory = $True)]$DependencyID,
                [switch]$UseWinAuth
            )
            if ($UseWinAuth) { $url += '/winauthwebservices' }
            $Path = "$Url/api/v1/secret-dependencies/$DependencyID"
            $params = @{
                Header      = $headers
                Uri         = $Path
                ContentType = 'application/json'
            }
            try {
                if ($usewinauth) {
                    $Dependency = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                    return $Dependency
                } else {
                    $Dependency = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
                    return $Dependency
                }
            } catch {
                Write-Log $("Error Getting Dependency: $Dependency" + $_)
                throw "Error Getting Dependency:  $Dependency" + $_
            }
        }
        function New-Dependency {
            param (
                [Parameter(Mandatory = $False)]$headers,
                [Parameter(Mandatory = $True)]$url,
                [Parameter(Mandatory = $True)]$SecretID,
                [Parameter(Mandatory = $True)]$SecretDependencyObject,
                [Parameter(Mandatory = $False)]$ServiceName,
                [Parameter(Mandatory = $False)]$MachineName,
                [switch]$UseWinAuth
            )
            if ($UseWinAuth) { $url += '/winauthwebservices' }
            $Path = "$Url/api/v1/secret-dependencies"
            if (!$MachineName) {
                $machineName = 'MachineNameNotProvided'
            }
            if (!$ServiceName) {
                $ServiceName = 'ServiceNameNotProvided'
            }
            $properties = [PSCustomObject]@{
                active                    = $SecretDependencyObject.active
                conditionDependencyId     = $SecretDependencyObject.conditionDependencyId
                conditionMode             = $SecretDependencyObject.conditionMode
                dependencyTemplate        = $SecretDependencyObject.dependencyTemplate
                description               = $SecretDependencyObject.description
                groupId                   = $SecretDependencyObject.groupId
                machineName               = $MachineName
                privilegedAccountSecretId = $SecretDependencyObject.privilegedAccountSecretId
                runScript                 = $SecretDependencyObject.runScript
                secretId                  = $SecretDependencyObject.secretId
                secretName                = $SecretDependencyObject.secretName
                serviceName               = $ServiceName
                settings                  = $SecretDependencyObject.settings
                sortOrder                 = $SecretDependencyObject.sortOrder
                sshKeySecretId            = $SecretDependencyObject.sshKeySecretId
                typeId                    = $SecretDependencyObject.typeId
                typeName                  = $SecretDependencyObject.typeName
            }
            $methodArgs = $properties | ConvertTo-Json -Depth 3
            $params = @{
                Header      = $headers
                Uri         = $Path
                Body        = $MethodArgs
                ContentType = 'application/json'
            }
            try {
                if ($usewinauth) {
                    $NewDependency = Invoke-RestMethod -Method Post @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                    return $NewDependency
                } else {
                    $NewDependency = Invoke-RestMethod -Method Post @params -ErrorAction SilentlyContinue
                    return $NewDependency
                }
            } catch {
                Write-Log $("Error Creating Dependency on Secret: $SecretID" + $_)
            }
        }
        function Get-DependencyStub {
            param (
                [Parameter(Mandatory = $False)]$headers,
                [Parameter(Mandatory = $True)]$url,
                [Parameter(Mandatory = $True)]$SecretID,
                [Parameter(Mandatory = $False)]$scriptId,
                [Parameter(Mandatory = $False)]$TemplateId,
                [Parameter(Mandatory = $False)]$TypeID,
                [switch]$UseWinAuth
            )
            if ($UseWinAuth) { $url += '/winauthwebservices' }
            $Path = "$Url/api/v1/secret-dependencies/stub?SecretID=$SecretID&scriptID=$ScriptID&TemplateID=$TemplateID&TypeId=$TypeID"
            $params = @{
                Header      = $headers
                Uri         = $Path
                ContentType = 'application/json'
            }
            try {
                if ($usewinauth) {
                    $NewDependencyStub = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                    return $NewDependencyStub
                } else {
                    $NewDependencyStub = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
                    return $NewDependencyStub
                }
            } catch {
                Write-Log $("Error Creating Dependency STUB: $SecretID" + $_)
                throw "Error Creating Dependency STUB: $SecretID" + $_
            }
        }
        function Get-DependencyGroups {
            param (
                [Parameter(Mandatory = $False)]$headers,
                [Parameter(Mandatory = $True)]$url,
                [Parameter(Mandatory = $True)]$SecretID,
                [switch]$UseWinAuth
            )
            if ($UseWinAuth) { $url += '/winauthwebservices' }
            $Path = "$Url/api/v1/secret-dependencies/groups/$SecretID"
            $params = @{
                Header      = $headers
                Uri         = $Path
                ContentType = 'application/json'
            }
            try {
                if ($usewinauth) {
                    $Dependency = Invoke-RestMethod -Method GET @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                    return $Dependency
                } else {
                    $Dependency = Invoke-RestMethod -Method GET @params -ErrorAction SilentlyContinue
                    return $Dependency
                }
            } catch {
                Write-Log $("Error Getting Dependency Groups: $Dependency" + $_)
            }
        }
        function New-DependencyGroupMap {
            param (
                [Parameter(Mandatory = $True)]$DependencyGroup,
                [switch]$ReverseOutput
            )
            $DependencyGroupTableMap = @{}
            foreach ($record in $DependencyGroup.model) {
                if ($reverseOutput) {
                    $DependencyGroupTableMap[$record.name] = $record.Id
                } else {
                    $DependencyGroupTableMap[$record.Id] = $record.name
                }
            }
            return $DependencyGroupTableMap
        }
        function New-DependencyGroup {
            param (
                [Parameter(Mandatory = $False)]$headers,
                [Parameter(Mandatory = $True)]$url,
                [Parameter(Mandatory = $True)]$SecretID,
                [Parameter(Mandatory = $True)]$SecretDependencyGroupName,
                [Parameter(Mandatory = $false)]$SiteID,
                [switch]$UseWinAuth
            )
            if ($UseWinAuth) { $url += '/winauthwebservices' }
            $Path = "$Url/api/v1/secret-dependencies/groups/$SecretID"

            $properties = @{
                'secretDependencyGroupName' = $SecretDependencyGroupName
                'siteId'                    = $SiteID
            }
            $MethodArgs = New-Object psObject -Property $properties | ConvertTo-Json
            $params = @{
                Header      = $headers
                Uri         = $Path
                Body        = $MethodArgs
                ContentType = 'application/json'
            }
            try {
                if ($usewinauth) {
                    $Dependency = Invoke-RestMethod -Method Post @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                    return $Dependency
                } else {
                    $Dependency = Invoke-RestMethod -Method Post @params -ErrorAction SilentlyContinue
                    return $Dependency
                }

            } catch {
                Write-Log $("Error Getting Dependency Groups: $Dependency" + $_)
                throw "Error Getting Dependency Groups:  $Dependency" + $_
            }
        }
        function Remove-Dependency {
            param (
                [Parameter(Mandatory = $false)] $headers,
                [Parameter(Mandatory = $True)]$url,
                [Parameter(Mandatory = $True)]$DependencyID,
                [switch]$UseWinAuth
            )
            if ($UseWinAuth) { $url += '/winauthwebservices' }
            $SecretPath = "$Url/api/v1/secret-dependencies/$DependencyID"
            $params = @{
                Header      = $headers
                Uri         = $SecretPath
                ContentType = 'application/json'
            }
            try {
                $Dependency = Invoke-RestMethod -Method Delete @params -UseDefaultCredentials -ErrorAction SilentlyContinue
                return $Dependency

            } catch {
                Write-Log -logitem $("Dependency Deletion Error on ID: $DependencyID" + $_)
            }
        }

        $SourceSOAPUrl = "$SourceUrl/webservices/SSWebservice.asmx?wsdl"
        $TargetSOAPUrl = "$TargetUrl/webservices/SSWebservice.asmx?wsdl"
        $SourceProxy = New-WebServiceProxy -uri $SourceSOAPUrl -UseDefaultCredential -Namespace 'ss'
        $TargetProxy = New-WebServiceProxy -uri $TargetSOAPUrl -UseDefaultCredential -Namespace 'ss'

        Write-Log $('Beginning thread for: ' + $SourceFolderName)

        #Get the secrets from the matching folders, and Migrate Files.
        $DuplicateTracker = @{}

        $SourceSecrets = $SourceProxy.SearchSecretsByFolder($SourceToken, '', $SourceFolderID, $false, $false, $true)
        $TargetSecrets = $TargetProxy.SearchSecretsByFolder($TargetToken, '', $TargetFolderID, $false, $false, $true)
        foreach ($SourceSecret in $SourceSecrets.SecretSummaries) {
            [bool]$Transfer = $false
            foreach ($TargetSecret in $TargetSecrets.SecretSummaries) {
                #check to see if the secret is a duplicate by checking for the "---###" at the end. If it is a duplicate, then strip the duplicate name off for comparison.
                #----------------------------------------------------
                $TargetSecretName = $TargetSecret.SecretName
                if ($TargetSecretName -like '*--*') {
                    $index = $TargetSecretName.LastIndexOf('--')
                    $substring = $TargetSecretName.Substring(0, $index)
                    $duplicateID = $TargetSecretName.Substring($index + 2)
                    if ($duplicateID -match '^\d+$') {
                        $TargetSecretName = $substring
                    }
                }
                #check to see if secret name and template match.
                if ($TargetSecretName.trim() -eq $SourceSecret.SecretName.trim() -and $TargetSecret.SecretTypeName -eq $SourceSecret.SecretTypeName) {
                    Write-Log $('Found Secret Match: ' + $TargetSecretName)
                    [int] $SourceSecretID = $SourceSecret.Secretid
                    [int] $TargetSecretID = $TargetSecret.SecretId

                    if ($DuplicateTracker.ContainsValue($TargetSecretID)) {
                        continue
                    }

                    $SourceDependencies = Get-SecretDependencies -headers $Sourceheaders -url $SourceUrl -SecretID $SourceSecretID
                    if (!$SourceDependencies.records) {
                        Write-Log $('No Dependencies Found, Skipping: ' + $TargetSecretName)
                        continue
                    }

                    $SourceDependencyGroup = Get-DependencyGroups -headers $Sourceheaders -url $SourceUrl -secretid $SourceSecretID
                    $SourceDependencyGroupMap = New-DependencyGroupMap -DependencyGroup $SourceDependencyGroup
                    $TargetDependencies = Get-SecretDependencies -headers $Targetheaders -url $TargetUrl -SecretID $TargetSecretID
                    $TargetDependencyGroup = Get-DependencyGroups -headers $Targetheaders -url $Targeturl -secretid $TargetSecretID

                    $Dependency = $null

                    if ($TargetDependencyGroup.model.count -ne $SourceDependencyGroup.model.count) {
                        Write-Log $('Creating Dependency Groups')
                        foreach ($model in $SourceDependencyGroup.model) {
                            Write-Log $model
                            if ($TargetDependencyGroup.model.name) {
                                if ($TargetDependencyGroup.model.name.contains($model.name)) {
                                    continue
                                }
                                if ($model.siteid) {
                                    $siteid = $TargetSites[$SourceSites[$model.siteid]]
                                    $null = New-DependencyGroup -headers $targetHeaders -url $targeturl -SecretID $TargetSecretID -SecretDependencyGroupName $model.name -SiteID $SiteID
                                    Write-Log $("Creating Dependency Group on: $TargetSecretID" + $TargetSecretName)
                                } else {
                                    $null = New-DependencyGroup -headers $targetHeaders -url $targeturl -SecretID $TargetSecretID -SecretDependencyGroupName $model.name
                                    Write-Log $("Creating Dependency Group on: $TargetSecretID" + $TargetSecretName)
                                }
                            } else {
                                if ($model.siteid) {
                                    $siteid = $TargetSites[$SourceSites[$model.siteid]]
                                    $null = New-DependencyGroup -headers $targetHeaders -url $targeturl -SecretID $TargetSecretID -SecretDependencyGroupName $model.name -SiteID $SiteID
                                    Write-Log $("Creating Dependency Group on: $TargetSecretID" + $TargetSecretName)
                                } else {
                                    $null = New-DependencyGroup -headers $targetHeaders -url $targeturl -SecretID $TargetSecretID -SecretDependencyGroupName $model.name
                                    Write-Log $("Creating Dependency Group on: $TargetSecretID" + $TargetSecretName)
                                }
                            }
                        }
                        $TargetDependencyGroup = Get-DependencyGroups -headers $Targetheaders -url $Targeturl -secretid $TargetSecretID
                    }

                    if ($TargetDependencies.records) {
                        foreach ($record in $TargetDependencies.records) {
                            Write-Log $('Deleteing Dependency on Target' + $Record.id)
                            Remove-Dependency -headers $TargetHeaders -url $TargetUrl -DependencyID $record.id
                        }
                    }

                    $TargetDependencyGroupMap = New-DependencyGroupMap -DependencyGroup $TargetDependencyGroup -reverseOutput

                    foreach ($Dependency in $SourceDependencies.records) {
                        $SourceDependency = Get-Dependency -headers $sourceheaders -url $sourceurl -DependencyID $Dependency.id
                        $stubParameters = @{
                            headers  = $TargetHeaders
                            url      = $TargetUrl
                            SecretID = $TargetSecretID
                        }
                        if ($SourceDependency.dependencyTemplate.secretDependencyTemplateId) {
                            $stubParameters['templateID'] = $TargetDependencyTemplatesMap[$SourceDependencyTemplatesMap[$SourceDependency.dependencyTemplate.secretDependencyTemplateId]]
                        } elseif ($Dependency.typeid -eq 7 -or $Dependency.typeid -eq 8 -or $Dependency.typeid -eq 9) {
                            $stubParameters['typeId'] = $Dependency.typeid
                            if ($SourceDependency.runScript.ScriptID) {
                                $stubParameters['scriptId'] = $TargetScripts[$sourcescripts[$sourcedependency.runScript.scriptid]]
                            }
                        }
                        $Stub = Get-DependencyStub @stubParameters
                        if ($SourceDependency.privilegedAccountSecretId) {
                            $PrivilegedSecret = search-Secret -headers $Targetheaders -url $TargetURL -SecretName $SourceDependency.Secretname
                            $Stub.privilegedAccountSecretId = $PrivilegedSecret.records[0].id
                            $Stub.secretName = $PrivilegedSecret.records[0].name
                        }
                        if ($SourceDependency.sshKeySecretId) {
                            $SSHSecret = Search-Secret -headers $Targetheaders -url $TargetURL -SecretName $SourceDependency.sshKeySecretName
                            $Stub.sshKeySecretId = $SSHSecret.records[0].id
                        }
                        $Stub.active = $SourceDependency.active
                        $Stub.conditionDependencyId = $SourceDependency.conditionDependencyId
                        $Stub.conditionMode = $SourceDependency.conditionMode
                        $Stub.description = $SourceDependency.description
                        $Stub.groupId = $TargetDependencyGroupMap[$SourceDependencyGroupMap[$SourceDependency.groupId]]
                        $Stub.secretId = $TargetSecretID
                        $Stub.sortOrder = $SourceDependency.sortOrder
                        $stub.settings = $SourceDependency.settings
                        if ($SourceDependency.runScript) {
                            $stub.runscript = $SourceDependency.runscript
                            if ($SourceDependency.runscript.scriptId) {
                                $stub.runscript.scriptid = $TargetScripts[$sourcescripts[$sourcedependency.runScript.scriptid]]
                            }
                        }
                        if ($SourceDependency.runScript.machineName) { $stub.runscript.machineName = $SourceDependency.runScript.machineName }
                        if ($sourcedependency.runscript.Servicename) { $stub.runscript.ServiceName = $sourcedependency.runscript.Servicename }
                        foreach ($field in $stub.dependencyTemplate.dependencyScanItemFields) {
                            $value = ($sourceDependency.dependencyTemplate.dependencyScanItemFields | Where-Object -Property 'name' -EQ $field.name).value
                            if ($value) {
                                $field.value = $value
                            } else {
                                $field.value = 'TestValue'
                            }
                        }
                        $NewDependency = New-Dependency -headers $targetheaders -url $Targeturl -secretid $TargetSecretID -SecretDependencyObject $stub -ServiceName $sourcedependency.runscript.Servicename -MachineName $SourceDependency.runScript.machineName
                        Write-Log $("New Dependency Created: $NewDependency")
                    }
                }
                if ($Transfer -eq $true) {
                    Break
                }
            }
        }
    }

    #Build Job Related Variables
    $MaxThreads = $ConcurrentJobs
    # $MaxWaitTime = 600
    $SleepTime = 500
    $Threads = @()
    $i = 0

    $SourceScripts = Get-DependencyScripts -headers $sourceheaders -url $SourceUrl -returntable
    $TargetScripts = Get-DependencyScripts -headers $Targetheaders -url $TargetUrl -returntable -ReverseOutput

    $SourceDependencyTemplatesMap = Get-SecretDependencyTemplates -headers $sourceheaders -url $sourceUrl -returnTable
    $TargetDependencyTemplatesMap = Get-SecretDependencyTemplates -headers $Targetheaders -url $TargetUrl -returnTable -ReverseOutput

    $SourceSites = Get-Sites -headers $sourceheaders -url $sourceurl -ReturnTable
    $TargetSites = Get-Sites -headers $targetheaders -url $targeturl -ReturnTable -ReverseOutput
    $SourceSites[1] = 'Default'

    foreach ($Key in $FolderMap.Keys) {
        $Parameter = @($SourceURL, $TargetURL, $SourceToken, $TargetToken, $Key, $FolderMap[$Key], $Log, $SourceFolderReference[$key].item(0), $SourceHeaders, $TargetHeaders, $SourceScripts, $TargetScripts, $SourceDependencyTemplatesMap, $TargetDependencyTemplatesMap, $SourceSites, $TargetSites)
        While ((Get-Job -State Running).count -gt $MaxThreads) {
            Write-Progress -Id 1 -Activity 'Waiting for existing jobs to complete' -Status "$($(Get-Job -State Running).count) jobs running" -PercentComplete ($i / $FolderMap.Count * 100)
            Start-Sleep -Milliseconds $SleepTime
        }

        # Start new jobs
        $i++
        $Threads += Start-Job -ScriptBlock $CodeContainer -Name $key -ArgumentList $Parameter[0], $Parameter[1], $Parameter[2], $Parameter[3], $Parameter[4], $Parameter[5], $Parameter[6], $Parameter[7], $Parameter[8], $Parameter[9], $Parameter[10], $Parameter[11], $Parameter[12], $Parameter[13], $Parameter[14], $Parameter[15]
        Write-Progress -Id 1 -Activity 'Starting jobs' -Status "$($(Get-Job -State Running).count) jobs running" -PercentComplete ($i / $FolderMap.Count * 100)
    }

    # All jobs have now been started
    # Wait for jobs to finish
    While ((Get-Job -State Running).count -gt 0) {
        $JobsStillRunning = ''
        foreach ($RunningJob in (Get-Job -State Running)) {
            $JobsStillRunning += $RunningJob.Name
        }
        Write-Progress -Id 1 -Activity 'Waiting for jobs to finish' -Status "$JobsStillRunning" -PercentComplete (($FolderMap.Count - (Get-Job -State Running).Count) / $FolderMap.Count * 100)
        Start-Sleep -Seconds '1'
    }

    # Output
    Write-Host 'Jobs Completed, printing output:'
    $ThreadErrors = @()
    $FailedJobs = @()
    $Jobs = Get-Job
    foreach ($j in $jobs) {
        [int] $ID = $j.name
        $ThreadError = $null
        $Name = $SourceFolderReference[$ID].item(0)
        Write-Host $Name 'job has completed.'
        if ($j.childjobs[0].error) {
            Write-Host 'Thread Erred'
            $ThreadError = $j.childjobs[0].error
            $FailedJobs += $j.name
        } else {
            $threadResults = Receive-Job -Job $j -ErrorVariable $ThreadError
        }
        if ($threadResults) {
            $MigratedSuccessfully += $threadResults[0]
            $NoMatches += $threadResults[1]
            $UnMatchedFields += $threadResults[2]
        }
        if ($ThreadError) {
            $ThreadErrors += $ThreadError
        }
    }
    # Cleanup
    Write-Host 'Cleaning Up jobs'
    Get-Job | Remove-Job

    # If any of the jobs encountered an error, just run that job again.
    if ($failedjobs.count -gt 0) {
        Write-Host 'Running any jobs that encountered errors again:'

        $Threads = @()
        $i = 0
        foreach ($item in $FailedJobs) {
            $Parameter = @($SourceURL, $TargetURL, $SourceToken, $TargetToken, $item, $FolderMap[[int]$item], $Log, $SourceFolderReference[[int]$item].item(0), $SourceHeaders, $TargetHeaders, $SourceScripts, $TargetScripts, $SourceDependencyTemplatesMap, $TargetDependencyTemplatesMap, $SourceSites, $TargetSites)
            While ((Get-Job -State Running).count -gt $MaxThreads) {
                Write-Progress -Id 1 -Activity 'Waiting for existing jobs to complete' -Status "$($(Get-Job -State Running).count) jobs running" -PercentComplete ($i / $FailedJobs.count * 100)
                Start-Sleep -Milliseconds $SleepTime
            }

            # Start new jobs
            $i++
            $Threads += Start-Job -ScriptBlock $CodeContainer -Name $item -ArgumentList $Parameter[0], $Parameter[1], $Parameter[2], $Parameter[3], $Parameter[4], $Parameter[5], $Parameter[6], $Parameter[7], $Parameter[8], $Parameter[9], $Parameter[10], $Parameter[11], $Parameter[12], $Parameter[13], $Parameter[14], $Parameter[15]
            Write-Progress -Id 1 -Activity 'Starting jobs' -Status "$($(Get-Job -State Running).count) jobs running" -PercentComplete ($i / $FailedJobs.count * 100)
            Start-Sleep -Milliseconds $SleepTime

        }
        # All jobs have now been started

        # Wait for jobs to finish
        While ((Get-Job -State Running).count -gt 0) {
            $JobsStillRunning = ''
            foreach ($RunningJob in (Get-Job -State Running)) {
                $JobsStillRunning += $RunningJob.Name
            }

            Write-Progress -Id 1 -Activity 'Waiting for jobs to finish' -Status "$JobsStillRunning" -PercentComplete (($FailedJobs.count - (Get-Job -State Running).Count) / $FailedJobs.count * 100)
            Start-Sleep -Seconds '1'
        }

        # Output
        Write-Host 'Jobs Completed, printing output:'
        $ThreadErrors = @()
        $FailedJobs = @()
        $Jobs = Get-Job
        foreach ($j in $Failedjobs) {
            [int] $ID = $j.name
            $ThreadError = $null
            $Name = $SourceFolderReference[$ID].item(0)
            Write-Host $Name 'job has completed.'
            if ($j.childjobs[0].error) {
                Write-Host 'Thread Erred'
                $ThreadError = $j.childjobs[0].error
                $FailedJobs += $j.name
            } else {
                $threadResults = Receive-Job -Job $j -ErrorVariable $ThreadError
            }
            if ($threadResults) {
                $MigratedSuccessfully += $threadResults[0]
                $NoMatches += $threadResults[1]
                $UnMatchedFields += $threadResults[2]
            }
            if ($ThreadError) {
                $ThreadErrors += $ThreadError
            }
        }

        # Cleanup
        Write-Host 'Cleaning Up jobs'
        Get-Job | Remove-Job
        Write-Host 'Errors after second run:'
        $ThreadErrors
    }
    $elapsed = $Stopwatch.Elapsed
    Write-Host "Script Finished. Elapsed time: $elapsed"
}
Invoke-DependencyMigration -SourceUrl $sourceUrl -TargetUrl $targetUrl -Log $logPath