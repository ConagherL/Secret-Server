$sourceUrl = 'https://'
$targeturl = 'https://'
$SecretCSV = Import-Csv -Path 'C:\SecretServer_Migration\Dependencies.csv'

<# Should not change anything below this line #>
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Log {
    param (
        [Parameter(Mandatory = $True, ValueFromPipeline = $True)] $logItem
    )
    $LogPath = 'C:\migration\DependencyMigration.txt'
    [string]$TimeStamp = Get-Date
    "[$TimeStamp]: " + $logitem | Out-File -FilePath $LogPath -Append
}
function Get-Token {
    param (
        [Parameter(Mandatory = $True)]$URL,
        [Parameter(Mandatory = $false)]$username,
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
        Write-Log $("Error Creating Dependency STUB: $NewDependencyStub" + $_)
        throw "Error Creating Dependency STUB:  $NewDependencyStub" + $_
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
        throw "Error Getting Dependency Groups:  $Dependency" + $_
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

Clear-Variable -Name SourceHeaders, TargetHeaders, SourceScripts, TargetScripts, SourceDependencyTemplatesMap, TargetDependencyTemplatesMap, SourceDependencies, SourceDependencyGroup, SourceDependencyGroupMap, TargetDependencies, TargetDependencyGroup -Force

$SourceHeaders = Get-Token -URL $SourceUrl
$TargetHeaders = Get-Token -URL $TargetUrl

$SourceScripts = Get-DependencyScripts -headers $SourceHeaders -url $sourceurl -returntable
$TargetScripts = Get-DependencyScripts -headers $Targetheaders -url $Targeturl -returntable -ReverseOutput

$SourceDependencyTemplatesMap = Get-SecretDependencyTemplates -headers $sourceheaders -url $sourceurl -returnTable
$TargetDependencyTemplatesMap = Get-SecretDependencyTemplates -headers $Targetheaders -url $Targeturl -returnTable -ReverseOutput

$count = 0
$total = $SecretCSV.Count
do {
    try {
        $TargetSecret = Search-Secret -Headers $TargetHeaders -url $TargetUrl -secretname $SecretCSV[$count].secretname
        if ($targetsecret.records.count -eq 1) {
            $TargetSecretID = $TargetSecret.records.id
        }
        $SourceSecretID = $SecretCSV[$count].secretid
        $SourceDependencies = Get-SecretDependencies -headers $Sourceheaders -url $SourceUrl -SecretID $SourceSecretID
        $SourceDependencyGroup = Get-DependencyGroups -headers $Sourceheaders -url $SourceUrl -secretid $SourceSecretID
        $SourceDependencyGroupMap = New-DependencyGroupMap -DependencyGroup $SourceDependencyGroup
        $TargetDependencies = Get-SecretDependencies -headers $Targetheaders -url $TargetUrl -SecretID $TargetSecretID
        $TargetDependencyGroup = Get-DependencyGroups -headers $Targetheaders -url $Targeturl -secretid $TargetSecretID

        $Dependency = $null
        if (!$SourceDependencies.records) {
            continue
        }

        if ($SourceDependencyGroup.model) {
            Write-Log $('Creating Dependency Groups')
            foreach ($model in $SourceDependencyGroup.model) {
                Write-Log $model
                if ($TargetDependencyGroup.model.name) {
                    if ($TargetDependencyGroup.model.name.contains($model.name)) {
                        continue
                    }
                    if ($model.siteid) {
                        $siteid = $model.siteId
                        $null = New-DependencyGroup -headers $targetHeaders -url $targeturl -SecretID $TargetSecretID -SecretDependencyGroupName $model.name -SiteID $SiteID
                        Write-Log $("Creating Dependency Group on: $TargetSecretID" + $TargetSecretName)
                    } else {
                        $null = New-DependencyGroup -headers $targetHeaders -url $targeturl -SecretID $TargetSecretID -SecretDependencyGroupName $model.name
                        Write-Log $("Creating Dependency Group on: $TargetSecretID" + $TargetSecretName)
                    }
                } else {
                    if ($model.siteid) {
                        $siteid = $model.siteId
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
                $SSHSecret = search-Secret -headers $Targetheaders -url $TargetURL -SecretName $SourceDependency.sshKeySecretName
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
    } catch {
        Write-log $('An Error Occurred Migrating Dependencies on Secret: ' + $SecretCSV[$Count].Targetid + ' Error Message: ' + $_ )
    }
    Write-Log $('Done Checking SecretID: ' + $SecretCSV[$Count].SecretName)
    $Count += 1
    Write-Progress -Activity 'Processing Dependency Data' -Status "Completed $count audits out of $total" -PercentComplete ($Count / $total * 100)
} while ($Count -lt $total)