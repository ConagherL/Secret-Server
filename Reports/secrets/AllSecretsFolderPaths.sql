SELECT
	s.SecretName AS 'Secret Name'
	,ISNULL(fp.FolderPath,'_No folder_') AS 'Folder Path'
FROM tbSecret s
LEFT JOIN tbFolder f
ON s.FolderId = f.FolderId
LEFT JOIN vFolderPath fp
ON f.FolderId = fp.FolderId
WHERE s.Active = 1
ORDER BY 2,1 ASC