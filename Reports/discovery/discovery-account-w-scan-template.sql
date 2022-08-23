/*
.PURPOSE
Account scan results with Scan Template, for managed and unmanaged
*/
SELECT
    ds.[Name] AS 'Discovery Source'
    ,ca.[AccountName] AS 'Account Name'
    ,ou.[Path] as 'OU'
    ,st.[ScanItemTemplateName] as 'Scan Template'
    ,CASE
        WHEN s.[SecretName] IS NULL then 'Unmanaged'
        ELSE s.[SecretName]
    END AS 'Secret Name'
    ,s.[SecretId]
FROM tbComputeraccount AS ca
INNER JOIN tbDiscoverySource AS ds ON ca.[DiscoverySourceId] = ds.[DiscoverySourceId]
INNER JOIN tbOrganizationUnit AS ou on ca.[OrganizationUnitId]	= ou.[OrganizationUnitId]
INNER JOIN tbScanItemTemplate AS st on ca.[ScanItemTemplateId] = st.[ScanItemTemplateId]
LEFT OUTER JOIN tbSecret AS s ON s.[ComputerAccountId] = ca.[ComputerAccountId]
WHERE [computerid] IS NULL
ORDER BY ca.[AccountName] ASC