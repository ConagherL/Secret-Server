$computerName = $args[0]
$scriptBlock = {
    Import-Module WebAdministration
    $webSites = Get-Website
    $dependencies = @()
    foreach ($webSite in $webSites) {
        $siteName = $webSite.name
        $filter = "system.applicationHost/sites/site[@name='$siteName']/application[@path='/']/virtualDirectory[@path='/']"
        $username = Get-WebConfigurationProperty $filter -Name "userName" | Where-Object Value -ne ''
        $ServiceName = Get-WebConfigurationProperty $filter -Name "physicalPath" | Where-Object Value -ne ''
        $path = Get-WebConfigurationProperty $filter -Name "path" | Where-Object Value -ne ''

        if ([string]::IsNullOrEmpty($username.Value)) {
            continue
        } else {
            #Only get the Directory name from the full path
            $serviceName = $ServiceName.Value.Substring($ServiceName.Value.LastIndexOf('\') + 1)
            $domain = $username.Value.Split("\")

            $object = [PSCustomObject]@{
                ComputerName     = $env:COMPUTERNAME
                ServiceName      = $serviceName
                VirtualDirectory = $path.Value
                Username         = $username.value.split("\")[1]
                Domain = $domain[0]
                ItemXpath = `"$filter`"
            }
            $dependencies += $object
        }
    }

    $virDirs = Get-WebVirtualDirectory
    foreach ($dir in $virDirs) {
        $filter = $dir.ItemXPath
        $filter = $filter.Substring(1)
        $username = Get-WebConfigurationProperty $filter -Name "username" | Where-Object Value -ne ''
        $serviceName = Get-WebConfigurationProperty $filter -Name "physicalpath" | Where-Object Value -ne ''
        $path = Get-WebConfigurationProperty $filter -Name "path" | Where-Object Value -ne ''
        if ([string]::IsNullOrEmpty($username.Value)) {
            continue
        } else {
            #clean up the path
            $path = $path.Value.Substring(1)
            #Only get the Directory name from the full path
            $serviceName = $serviceName.Value.Substring($serviceName.Value.LastIndexOf('\') + 1)
            $domain = $username.Value.Split("\")

            $object = [PSCustomObject]@{
                ComputerName     = $env:COMPUTERNAME
                ServiceName      = $serviceName
                VirtualDirectory = $path
                Username         = $username.value.split("\")[1]
                Domain           = $domain[0]
                ItemXpath        = `"$filter`"
            }
            $dependencies += $object
        }
    }

    $apps = Get-WebApplication
    foreach ($app in $apps) {
        $filter = $app.ItemXPath
        $filter = "$filter/virtualDirectory[@path='/']"
        $filter = $filter.Substring(1)

        $username = Get-WebConfigurationProperty $filter -Name "username" | Where-Object Value -ne ''
        $serviceName = Get-WebConfigurationProperty $filter -Name "physicalPath" | Where-Object Value -ne ''
        $path = Get-WebConfigurationProperty $filter -Name "path" | Where-Object Value -ne ''
        if ([string]::IsNullOrEmpty($username.Value)) {
            continue
        } else {
            #Only get the Directory name from the full path
            $serviceName = $ServiceName.Value.Substring($ServiceName.Value.LastIndexOf('\') + 1)
            $domain = $username.Value.Split("\")

            $object = [PSCustomObject]@{
                ComputerName     = $env:COMPUTERNAME
                ServiceName      = $serviceName
                VirtualDirectory = $path
                Username         = $username.value.split("\")[1]
                Domain           = $domain[0]
                ItemXpath        = `"$filter`"
            }
            $dependencies += $object
        }
    }
    return $dependencies
}

Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock