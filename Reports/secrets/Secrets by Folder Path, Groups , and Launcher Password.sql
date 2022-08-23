SELECT	
		f.FolderPath As [Folder Path]
		,s.SecretName AS [Secret Name]
		,gdn.[DisplayName] AS [Group]
		,gfp.[Permissions]
		,gfp.[Inherit Permissions]
		,CASE 
			WHEN S.HideLauncherPassword > 0 THEN 'Yes'
			WHEN S.HideLauncherPassword <=0 THEN 'No'
		ELSE 'N/A'
			END AS 'Hide Launcher Password'
	
	FROM  vGroupFolderPermissions gfp WITH (NOLOCK)
	INNER JOIN tbFolder f WITH (NOLOCK)
		ON f.FolderId = gfp.FolderId
	INNER JOIN vGroupDisplayName gdn WITH (NOLOCK)
		ON gdn.GroupId = gfp.GroupId
	INNER JOIN tbGroup g WITH (NOLOCK)
		ON g.GroupId = gfp.GroupId
	INNER JOIN tbSecret s
		ON s.FolderId = f.FolderID
	WHERE
		g.Active = 1
		AND
		g.IsPersonal = 0	           

	ORDER BY f.FolderPath, s.SecretName, gdn.DisplayName ASC