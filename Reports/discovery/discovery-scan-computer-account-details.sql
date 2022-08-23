/*
.PURPOSE
Computer and Account details from discovery scan
*/
SELECT
    ds.[Name] AS 'Discovery Source'
    ,ou.[Path] 'Organizational Unit'
    ,c.[ComputerName] AS 'Host Name'
    ,c.[ComputerVersion] AS 'Operating System'
    ,ca.[AccountName] AS 'Account Name'
    ,st.[ScanItemTemplateName] AS 'Account Type'
    ,CASE
        WHEN ca.[ScanItemTemplateId] = 13 AND ca.[IsLocalAdministrator] = 1 THEN 'Built-in Administrator'
        WHEN ca.[ScanItemTemplateId] = 13 AND ca.[IsLocalAdministrator] = 0 THEN 'Standard_User'
    END AS 'Account Privilege'
    ,CASE
        WHEN ca.[ScanItemTemplateId] =13 AND ca.[IsLocalAdministrator] = 1 THEN 'Yes'
        WHEN ca.[ScanItemTemplateId] =13 AND ca.[IsLocalAdministrator] =0 THEN 'No'
    END AS 'Has Local Admin Rights'
    ,CASE WHEN ca.[PasswordLastSet] IS NULL THEN 'Never'
        ELSE CONVERT(NVARCHAR,ca.[PasswordLastSet])
    END AS 'Password Last Set'
    ,c.[LastPolledDate] AS 'Last Scanned'
    ,CASE
        WHEN s.[SecretName] IS NULL THEN 'Unmanaged'
        ELSE s.[SecretName]
    END AS 'Secret Name'
FROM tbComputer AS c
INNER JOIN tbComputerAccount AS ca ON ca.[ComputerID] = c.[ComputerId]
INNER JOIN tbOrganizationUnit AS ou ON c.[OrganizationUnitId] = ou.[OrganizationUnitId]
INNER JOIN tbScanItemTemplate AS st ON ca.[ScanItemTemplateId] = st.[ScanItemTemplateId]
INNER JOIN tbDiscoverySource AS ds ON c.[DiscoverySourceId] = ds.[DiscoverySourceId]
LEFT OUTER JOIN tbSecret AS s ON s.[ComputerAccountId] = ca.[ComputerAccountId]
ORDER BY c.[ComputerName] ASC