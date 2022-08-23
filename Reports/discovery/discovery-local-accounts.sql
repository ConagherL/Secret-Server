/*
.PURPOSE
Get list of local accounts found in discovery scanning
*/
SELECT
    (SELECT Name FROM tbDiscoverySource AS ds WHERE DiscoverySourceId = c.DiscoverySourceId) AS 'Source'
    ,c.ComputerName AS Computer
    ,ca.AccountName AS 'Account'
    ,c.ComputerVersion AS 'OS'
    ,(SELECT Path FROM tbOrganizationUnit ou WHERE c.OrganizationUnitId = ou.OrganizationUnitId) AS Path
    ,(SELECT s.SecretName FROM tbSecret s WHERE s.ComputerAccountId = ca.ComputerAccountId) AS 'Secret'
    ,CAST(c.LastPolledDate AS SMALLDATETIME) AS 'Last Scanned'
    ,CASE  WHEN ca.ComputerAccountId IS NULL THEN 'Unmanaged' ELSE 'Managed' END AS 'Managed'
    ,c.LastErrorMessage AS 'Status'
FROM tbComputerAccount AS ca
RIGHT OUTER JOIN tbComputer AS c ON ca.ComputerId = c.ComputerId
ORDER BY Computer