/*
.PURPOSE
Query parses the JSON data stored in AdditionalData column of tbComputerAccount. Only supported on SQL Server 2016+ and Azure SQL
Use filter to focus on specific Scan Template - example is for Active Directory pulling additional attribute data
*/
SELECT
    d.[ComputerAccountId]
    ,d.[CreatedDate]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'Domain' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [Domain]
    ,d.[AccountName] AS [Username]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'SamAccountName' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [SamAccountName]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'DisplayName' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [DisplayName]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'ExtensionAttribute14' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [ExtensionAttribute14]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'ExtensionAttribute01' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [mail]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'UserPrincipalName' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [UserPrincipalName]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'sn' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [sn]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'Active' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [Enabled]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'PasswordExpired' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [PasswordExpired]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'ExtensionAttribute02' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [Manager]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'UserAccountControl' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [UserAccountControl]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'PwdLastSet' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [PwdLastSet]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'PwdAge' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [PwdAge]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'LastLogonTimestamp' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [LastLogonTimestamp]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'WhenCreated' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [WhenCreated]
    ,MIN(CASE JSON_VALUE([adata].[value],'$.Name') WHEN 'DistinguishedName' THEN JSON_VALUE([adata].[value],'$.Value') END) AS [DistinguishedName]
FROM tbComputerAccount AS d
CROSS APPLY OPENJSON (d.AdditionalData) AS adata
INNER JOIN tbScanItemTemplate AS s ON s.ScanItemTemplateId = d.ScanItemTemplateId
WHERE s.ScanItemTemplateName LIKE 'AD%Attributes%Scan Template'
GROUP BY d.ComputerAccountId, d.AccountName, d.CreatedDate