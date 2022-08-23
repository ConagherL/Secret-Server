/*
.PURPOSE
Gets list of dependencies and provide details on computer, account and dependency type
*/
SELECT
    ds.[Name] AS 'Discovery Source'
    ,c.[ComputerName] AS 'Host Name'
    ,c.[ComputerVersion] AS 'Operating System'
    ,cd.[AccountName] AS 'Account Name'
    ,cd.[DependencyName] AS 'Dependency Name'
    ,sdt.[SecretDependencyTypeName] AS 'Dependency Type'
    ,c.[LastPolledDate] AS 'Last Scanned',
    CASE
        WHEN s.[SecretName] IS NULL then 'Unmanaged'
        ELSE s.[SecretName]
    END AS 'Secret Name'
FROM tbComputer AS c
INNER JOIN tbComputerDependency cd ON cd.[ComputerID] = c.[ComputerId]
INNER JOIN tbSecretDependencyType sdt ON sdt.[SecretDependencyTypeId] = cd.[SecretDependencyTypeID]
INNER JOIN tbSecretDependencyTemplate sdtm ON cd.[ScanItemTemplateId] = sdtm.[ScanItemTemplateId] AND cd.[SecretDependencyTypeID] = sdtm.[SecretDependencyTypeId]
INNER JOIN tbDiscoverySource ds ON c.[DiscoverySourceId] = ds.[DiscoverySourceId]
LEFT OUTER JOIN tbSecret s ON s.[SecretID] = cd.[SecretId]
ORDER BY c.[ComputerName] ASC