SELECT si.SiteName AS 'Site Name',fo.FolderPath AS 'Folder Path' ,t.SecretTypeName AS 'Secret Template',fo.FolderName AS 'FolderName',i.ItemValue as 'Domain',s.SecretName,t.SecretTypeName AS 'Secret Template'
FROM tbSecret AS s
       INNER JOIN tbFolder fo
	   ON FO.FolderID = S.FolderId
	   INNER JOIN tbSecretType t
	   ON t.SecretTypeID = s.SecretTypeID
	   INNER JOIN tbSite si
	   ON si.SiteId = s.SiteId
	   INNER JOIN tbSecretItem i
	   ON i.SecretID = s.SecretID
WHERE s.Active =1 and t.SecretTypeName = 'Active Directory Account'
ORDER BY si.SiteName ,fo.FolderPath ASC