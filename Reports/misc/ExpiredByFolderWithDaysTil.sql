SELECT
	CASE
		WHEN tbSecret.IsCustomExpiration = 1 THEN DATEADD(DD, tbSecret.CustomExpirationDays,tbSecret.ExpiredFieldChangedDate)
		ELSE DATEADD(DD, tbSecretType.ExpirationDays,tbSecret.ExpiredFieldChangedDate)
	END AS 'Expiration Date'
	,IsNull(vFolderPath.FolderPath, 'No Folder') AS 'Folder Path'
	,tbSecret.SecretName AS 'Secret Name'
	,tbSecretType.SecretTypeName AS 'Secret Template'
	,CASE
		WHEN tbSecret.IsCustomExpiration = 1 THEN DATEDIFF(dd,GETDATE(),DATEADD(DD, tbSecret.CustomExpirationDays,tbSecret.ExpiredFieldChangedDate))
		ELSE DATEDIFF(dd,GETDATE(),DATEADD(DD, tbSecretType.ExpirationDays,tbSecret.ExpiredFieldChangedDate))
	END AS 'Days Until Expiration' 
FROM
	tbSecret WITH (NOLOCK)
INNER JOIN tbSecretType WITH (NOLOCK)
	ON tbSecretType.SecretTypeId = tbSecret.SecretTypeId
LEFT JOIN tbFolder WITH (NOLOCK)
	ON tbSecret.FolderId = tbFolder.FolderId
LEFT JOIN vFolderPath WITH (NOLOCK)
	ON tbFolder.FolderId = vFolderPath.FolderId
WHERE
	tbSecretType.ExpirationFieldId > 0
	AND
		(
			(
				--secret has no custom expiration, secret expires within 10 days from today
				tbSecret.IsCustomExpiration = 0 AND DATEADD(DD, tbSecretType.ExpirationDays,tbSecret.ExpiredFieldChangedDate) <= DATEADD(DD, 10, GETDATE()) 
				AND
				tbSecretType.ExpirationDays > 0
			)  
			OR
			--secret has no custom expiration, secret has expired
			--tbSecret.IsCustomExpiration = 0 AND DATEADD(DD, tbSecretType.ExpirationDays,tbSecret.ExpiredFieldChangedDate) <= GETDATE()   
			--OR;l
			--secret has custom expiration,  Secret expires within 10 days from today
			tbSecret.IsCustomExpiration = 1 AND DATEADD(DD, tbSecret.CustomExpirationDays,tbSecret.ExpiredFieldChangedDate) <= DATEADD(DD, 10, GETDATE())  
			--OR
			--secret has custom expiration, Secret has expired
			--tbSecret.IsCustomExpiration = 1 AND DATEADD(DD, tbSecret.CustomExpirationDays,tbSecret.ExpiredFieldChangedDate) <= GETDATE()  

		)
AND tbSecret.Active = 1
AND (tbfolder.FolderPath = #CUSTOMTEXT)
ORDER BY
	1, 2, 3, 4
