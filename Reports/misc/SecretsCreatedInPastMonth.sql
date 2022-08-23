SELECT
	s.SecretName AS [Secret name]
	,s.SecretID
	,st.SecretTypeName AS [Secret type]
	,s.Created AS [Date/Time created]
	,ISNULL(fp.FolderPath,'_No folder_') AS 'Folder Path'
	
FROM
	tbSecret s
JOIN
	tbSecretType st WITH (NOLOCK)
	ON
	s.SecretTypeId = st.SecretTypeId
LEFT JOIN tbFolder f
ON s.FolderId = f.FolderId
LEFT JOIN vFolderPath fp
ON f.FolderId = fp.FolderId
WHERE
	s.Created >= (GETDATE() - 30)
ORDER BY 
s.Created DESC