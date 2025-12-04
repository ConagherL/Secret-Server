SELECT c.ComputerName as Computer
      ,cd.AccountDomain + '\' + cd.AccountName as [Service Account]
      ,cd.DependencyName as [Service Name]
	  ,sit.ScanItemTemplateName as [Scan Template]
      ,s.SecretId
	  ,s.secretname as [Secret Name]
	  ,ds.Name as [Discovery Source]
	  ,case when cd.SecretDependencyId is NULL then 'Unmanaged' else 'Managed' End as [Status]
  FROM [dbo].[tbComputerDependency] cd
  left join tbSecret s on s.SecretID = cd.SecretId
  right join tbComputer c on c.ComputerID = cd.ComputerId
  left join tbScanItemTemplate sit on cd.ScanItemTemplateId = sit.ScanItemTemplateId
  left join tbDiscoverySource ds on c.DiscoverySourceId = ds.DiscoverySourceId
  where ds.Active = 1 and ds.Name like '%' + #CUSTOMTEXT + '%' and cd.DependencyName IS NOT Null
