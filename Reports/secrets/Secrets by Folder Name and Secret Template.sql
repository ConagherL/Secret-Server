SELECT fo.FolderName,s.SecretName,t.SecretTypeName AS 'Secret Template'
FROM tbSecret AS s
       INNER JOIN tbFolder fo
	   ON FO.FolderID = S.FolderId
	   INNER JOIN tbSecretType t
	   ON t.SecretTypeID = s.SecretTypeID
WHERE s.Active =1
ORDER BY fo.FolderName ASC