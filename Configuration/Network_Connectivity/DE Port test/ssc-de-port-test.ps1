<#
.SYNOPSIS
This script can be used to verify network and firewall access to Secret Server Cloud tenant and Azure Service Bus.
.NOTES
It does require obtaining the Customer Service Bus hostname from your tenant. Browse to https://<tenant URL>/AdminDiagnostics.aspx to grab this hostname.

Details on IP and Hostnames collected are from public documentation:
- https://docs.thycotic.com/ss/11.0.0/secret-server-setup/upgrading/ssc-ip-change-3-21#new_ip_addresses_and_hostnames
- https://docs.thycotic.com/ss-arc/1.0.0/secret-server/secret-server-cloud

.EXAMPLE
.\ssc-network-test.ps1 -SecretServer 'https://proservices.secretservercloud.com' -CustomerServiceBus 'sb-d7cf91b8-6279-47fc-943c-411a0bdb4701.servicebus.windows.net' -TransportType AMQP -Timeout 5

Run Hostname and IP port test for Tenant and Service Bus with ports 5671 and 5672 for AMQP, with a timeout of 5 seconds

.EXAMPLE
.\ssc-network-test.ps1 -SecretServer 'https://proservices.secretservercloud.com' -CustomerServiceBus 'sb-d7cf91b8-6279-47fc-943c-411a0bdb4701.servicebus.windows.net'

Run Hostname and IP port test for Tenant and Service Bus with port 443 (Web Sockets), with a default timeout of 3 seconds
#>
[cmdletbinding()]
param(
    # Secret Server Tenant URL
    [uri]
    $SecretServer,

    # Customer Service Bus found in diagnostic page
    [string]
    $CustomerServiceBus,

    # Azure ServiceBus Transport Type (Admin > Distributed Engine > Configuration tab)
    [ValidateSet('WebSockets','AMQP')]
    [string]
    $TransportType = 'WebSockets',

    # Timeout for connection test, defaults to 3 seconds
    [int]
    $Timeout = 3
)
begin {
    $domainsRaw = "
    US, secretservercloud.com
    AU, secretservercloud.com.au
    CA, secretservercloud.ca
    EU, secretservercloud.eu
    SG, secretservecloud.com.sg"
    $domains = $domainsRaw | ConvertFrom-Csv -Header 'Region', 'Domain'
    #region IPs
    $domainIPsRaw = "
    secretservercloud.com, 52.224.253.7
    secretservercloud.com, 52.224.253.4
    secretservercloud.com.au, 20.37.251.37
    secretservercloud.com.au, 20.37.251.120
    secretservercloud.ca, 52.228.117.246
    secretservercloud.ca, 52.228.113.119
    secretservercloud.eu, 20.79.64.213
    secretservercloud.eu, 20.79.65.3
    secretservercloud.com.sg, 20.195.97.220
    secretservercloud.com.sg, 20.195.98.154"
    $domainIPs = $domainIPsRaw | ConvertFrom-Csv -Header 'Domain', 'HostAddress'
    #endregion IPs

    #region Hosts
    $sbHostsRaw = "
    secretservercloud.com, thycotic-ssc-us-er-sb-01-prod-b.servicebus.windows.net
    secretservercloud.com, thycotic-ssc-us-er-sb-01-prod-g.servicebus.windows.net
    secretservercloud.com, thycotic-ssc-us-er-sb-02-prod-b.servicebus.windows.net
    secretservercloud.com, thycotic-ssc-us-er-sb-02-prod-g.servicebus.windows.net
    secretservercloud.com.au, thycotic-ssc-au-er-sb-01-prod-b.servicebus.windows.net
    secretservercloud.com.au, thycotic-ssc-au-er-sb-01-prod-g.servicebus.windows.net
    secretservercloud.com.au, thycotic-ssc-au-er-sb-02-prod-b.servicebus.windows.net
    secretservercloud.com.au, thycotic-ssc-au-er-sb-02-prod-g.servicebus.windows.net
    secretservercloud.ca, thycotic-ssc-ca-er-sb-01-prod-b.servicebus.windows.net
    secretservercloud.ca, thycotic-ssc-ca-er-sb-01-prod-g.servicebus.windows.net
    secretservercloud.ca, thycotic-ssc-ca-er-sb-02-prod-b.servicebus.windows.net
    secretservercloud.ca, thycotic-ssc-ca-er-sb-02-prod-g.servicebus.windows.net
    secretservercloud.eu, thycotic-ssc-eu-er-sb-01-prod-b.servicebus.windows.net
    secretservercloud.eu, thycotic-ssc-eu-er-sb-01-prod-g.servicebus.windows.net
    secretservercloud.eu, thycotic-ssc-eu-er-sb-02-prod-b.servicebus.windows.net
    secretservercloud.eu, thycotic-ssc-eu-er-sb-02-prod-g.servicebus.windows.net
    secretservercloud.com.sg, thycotic-ssc-sea-er-sb-01-prod-b.servicebus.windows.net
    secretservercloud.com.sg, thycotic-ssc-sea-er-sb-01-prod-g.servicebus.windows.net
    secretservercloud.com.sg, thycotic-ssc-sea-er-sb-02-prod-b.servicebus.windows.net
    secretservercloud.com.sg, thycotic-ssc-sea-er-sb-02-prod-g.servicebus.windows.net"
    $sbHosts = $sbHostsRaw | ConvertFrom-Csv -Header 'Domain', 'HostAddress'
    #endregion Hosts
    $testPortServiceBus =
    switch ($TransportType) {
        'WebSockets' { 443 }
        'AMQP' { 5671,5672 }
    }
}
process {
    Write-Host "[INFO] Secret Server Tenant: $SecretServer"

    $regionDomain = $domains | Where-Object { $SecretServer.Host -match $_.Domain }
    $region = $regionDomain.Region
    $domain = $regionDomain.Domain
    Write-Host "[INFO] Setting region to: $region"
    Write-Host "[INFO] Host domain for Secret Server Cloud: $domain"

    $testSBHosts = $sbHosts.Where({ $_.Domain -eq $domain })
    $testDomainIPs = $domainIPs.Where({ $_.Domain -eq $domain })
    $results = @()

    <# Test Tenant URL #>
    Write-Host "[INFO] Testing Secret Server Tenant [$SecretServer] on port [443]"
    $ssTcp = [System.Net.Sockets.TcpClient]::new()
    $ssResult = [pscustomobject]@{
        Category    = 'Tenant URL'
        HostAddress = $SecretServer.Host
        Port        = 443
        Status      = $null
    }
    if ($ssTcp.ConnectAsync($SecretServer.Host,443).Wait([timespan]::FromSeconds($Timeout))) {
        Write-Host "[WARNING] `tSB Host test failed on port [$port]"
        $ssResult.Status = 'Failed'
    } else {
        Write-Host "`tSB Host test successful"
        $ssResult.Status = 'Successful'
    }
    $results += $ssResult

    foreach ($port in $testPortServiceBus) {
        <# Test Customer Service Bus #>
        Write-Host "[INFO] Testing Customer Service Bus [$CustomerServiceBus] on port [$port]"
        $cSbTcp = [System.Net.Sockets.TcpClient]::new()
        $cSbResult = [pscustomobject]@{
            Category    = 'Customer Service Bus Hostname'
            HostAddress = $CustomerServiceBus
            Port        = $port
            Status      = $null
        }
        if ($cSbTcp.ConnectAsync($CustomerServiceBus,$port).Wait([timespan]::FromSeconds($Timeout))) {
            Write-Host "[WARNING] `tSB Host test failed on port [$port]"
            $cSbResult.Status = 'Failed'
        } else {
            Write-Host "`tSB Host test successful"
            $cSbResult.Status = 'Successful'
        }
        $results += $cSbResult

        <# Test Azure Service Bus Hostname connection #>
        foreach ($sbHost in $testSBHosts) {
            $currentSBResult = [pscustomobject]@{
                Category    = 'Azure Service Bus Hostname'
                HostAddress = $sbHost.HostAddress
                Port        = $port
                Status      = $null
            }
            $sbTcp = [System.Net.Sockets.TcpClient]::new()
            Write-Host "[INFO] Testing SB host: [$($sbHost.HostAddress)]"
            if ($sbTcp.ConnectAsync($sbHost.HostAddress,$port).Wait([timespan]::FromSeconds($Timeout))) {
                Write-Host "[WARNING] `tSB Host test failed on port [$port]"
                $currentSBResult.Status = 'Failed'
            } else {
                Write-Host "`tSB Host test successful"
                $currentSBResult.Status = 'Successful'
            }
            $sbTcp.Close()
            $sbTcp.Dispose()
            $results += $currentSBResult
        }
    }
    <# Test Domain IPs #>
    foreach ($domainIP in $testDomainIPs) {
        $currentIPResult = [pscustomobject]@{
            Category    = 'Tenant Domain IP'
            HostAddress = $domainIP.HostAddress
            Port        = 443
            Status      = $null
        }
        $dTcp = [System.Net.Sockets.TcpClient]::new()
        Write-Host "[INFO] Testing domain [$($domainIp.Domain)] IP: [$($domainIP.HostAddress)]"
        if ($dTcp.ConnectAsync($domainIP.HostAddress,443).Wait([timespan]::FromSeconds($Timeout))) {
            Write-Host "[WARNING] `t$($domainIp.Domain) IP test failed on port [443]"
            $currentIPResult.Status = 'Failed'
        } else {
            Write-Host "`t$($domainIp.Domain) IP test successful"
            $currentIPResult.Status = 'Successful'
        }
        $dTcp.Close()
        $dTcp.Dispose()
        $results += $currentIPResult
    }
    Write-Host "`t***Test Complete**"
    $results | Sort-Object Category
}