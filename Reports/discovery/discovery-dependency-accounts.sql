/*
.PURPOSE
Get list of dependencies found during discovery scanning with additional details
*/
SELECT
    (SELECT [Name] FROM tbDiscoverySource ds WHERE ds.DiscoverySourceId = c.DiscoverySourceId) AS 'Source'
    ,cd.AccountDomain AS 'Domain'
    ,c.ComputerName AS 'Computer'
    ,cd.AccountName AS 'Account'
    ,cd.DependencyName AS 'Service Name'
    ,(SELECT SecretDependencyTypeName FROM tbSecretDependencyType sdt WHERE sdt.SecretDependencyTypeId = cd.SecretDependencyTypeID) AS 'Dependency Type'
    ,(SELECT s.SecretName FROM tbSecret s WHERE s.SecretID = cd.SecretId) AS 'Secret'
    , CAST(c.LastPolledDate AS smalldatetime) as 'Last Scanned'
FROM tbComputer AS c
LEFT OUTER JOIN tbComputerDependency AS cd ON cd.ComputerID = c.ComputerId
ORDER BY c.ComputerName