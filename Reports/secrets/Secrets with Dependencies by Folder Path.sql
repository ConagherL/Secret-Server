SELECT 
	f.FolderPath AS [Folder Path],
	s.SecretName AS [Secret Name],
	d.MachineName AS [Server Name],
	d.ServiceName AS [Dependency Name]
FROM tbSecret s
JOIN tbSecretDependency d
ON d.SecretId = s.SecretID
JOIN tbFolder f
on f.FolderID = s.FolderId
WHERE f.FolderPath = #FOLDERPATH