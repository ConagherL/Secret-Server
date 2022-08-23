SELECT si.SiteName AS 'Site Name',fo.FolderPath AS 'Folder Path' ,fo.FolderName AS 'FolderName',s.SecretName,t.SecretTypeName AS 'Secret Template'
FROM tbSecret AS s
       INNER JOIN tbFolder fo
	   ON FO.FolderID = S.FolderId
	   INNER JOIN tbSecretType t
	   ON t.SecretTypeID = s.SecretTypeID
	   INNER JOIN tbSite si
	   ON si.SiteId = s.SiteId
WHERE s.Active =1
ORDER BY si.SiteName ,fo.FolderPath ASC