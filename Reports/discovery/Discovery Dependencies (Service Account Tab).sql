SELECT 
cd.AccountDomain AS 'Domain',
cd.AccountName AS 'Account',
c.ComputerName AS 'Host Name',
c.ComputerVersion AS 'Operating System',
cd.DependencyName AS 'Dependency Name',
sdt.SecretDependencyTypeName AS 'Dependency Type',
SDTM.SecretDependencyTemplateName AS 'Dependency Template Name',
c.LastPolledDate AS 'Last Scanned',
s.SecretName
FROM 
tbComputer c
JOIN tbComputerDependency cd ON cd.ComputerID = c.ComputerId
JOIN tbSecretDependencyType sdt ON sdt.SecretDependencyTypeId = cd.SecretDependencyTypeID
JOIN tbSecretDependencyTemplate sdtm ON cd.ScanItemTemplateId = sdtm.ScanItemTemplateId
    AND cd.SecretDependencyTypeID = sdtm.SecretDependencyTypeId
LEFT OUTER JOIN tbSecret s ON s.SecretID = cd.SecretId
Where
cd.AccountName like '%' + #CUSTOMTEXT + '%'
