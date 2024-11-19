SELECT
	s.SecretName AS [Secret Name]
	,ISNULL(si.ItemValue, N'No Username field') AS [Username]
	,ISNULL(fp.FolderPath, N'No folder assigned') AS [Folder Path]
	,s.SecretID
FROM
	tbSecret s
JOIN
	tbSecretField sf WITH (NOLOCK)
	ON s.SecretTypeID = sf.SecretTypeID
JOIN
	tbSecretItem si WITH (NOLOCK)
	ON sf.SecretFieldID = si.SecretFieldID
	AND s.SecretID = si.SecretID
LEFT JOIN
	vFolderPath fp WITH (NOLOCK)
	ON s.FolderId = fp.FolderId
WHERE sf.SecretFieldName = 'UserName'
AND s.Active = 1
ORDER BY s.SecretID ASC