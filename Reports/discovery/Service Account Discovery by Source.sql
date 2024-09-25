select  c.ComputerName as Computer
      ,ca.AccountName as Account
	  ,sit.ScanItemTemplateName as [Scan Template]
	  ,c.ComputerVersion as [OS]
	  ,c.DistinguishedName as Container
	  ,s.SecretID
	  ,s.SecretName
	  ,ca.FoundOnComputer
	  ,c.LastPolledDate as [Last Scanned]
	  ,DATEDIFF (DAY,c.LastLogon,GETDATE()) AS [Last Connected]
	  ,case when ca.HasLocalAdminRights  like '1' then 'Yes' else 'No' End as [Is Local Admin]
	  ,case when ca.IsLocalAdministrator like '1' then 'Yes' else 'No' End as [Has Admin Rights]
	  ,DATEDIFF (DAY,ca.PasswordLastSet,GETDATE()) AS [Days Since PWD Change]
	  ,CASE
		WHEN ca.PasswordExpirationStatus = '0' THEN 'Unknown'
		WHEN ca.PasswordExpirationStatus = '1' THEN 'Normal'
		WHEN ca.PasswordExpirationStatus = '2' THEN 'DoesNotExpire'
		WHEN ca.PasswordExpirationStatus = '3' THEN 'MustChangeOnNextLogin'
		WHEN ca.PasswordExpirationStatus = '4' THEN 'Expired'
		END as 'Expiration Status'
      ,ds.Name as [Discovery Source]
	  ,case when s.SecretID is NULL then 'Unmanaged' else 'Managed' End as [Status]
from tbComputer c
left join tbComputerAccount ca on ca.ComputerId = c.ComputerId
left join tbDiscoverySource ds on c.DiscoverySourceId = ds.DiscoverySourceId
left join tbScanItemTemplate sit on c.ScanItemTemplateId = sit.ScanItemTemplateId
LEFT JOIN tbSecret s ON ca.ComputerAccountId = s.ComputerAccountId
where ds.Active = 1 and ds.Name like '%' + #CUSTOMTEXT + '%'