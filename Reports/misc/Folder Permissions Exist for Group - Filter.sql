SELECT	
		f.FolderPath As [Folder Path]
		,f.FolderName As [Folder Name]
		,gfp.[Inherit Permissions]
		,gdn.[DisplayName] AS [Group]
		,gfp.[Permissions]
		,gfp.[Color]	
	FROM  vGroupFolderPermissions gfp WITH (NOLOCK)
	INNER JOIN tbFolder f WITH (NOLOCK)
		ON f.FolderId = gfp.FolderId
	INNER JOIN vGroupDisplayName gdn WITH (NOLOCK)
		ON gdn.GroupId = gfp.GroupId
	INNER JOIN tbGroup g WITH (NOLOCK)
		ON g.GroupId = gfp.GroupId
	WHERE

    f.folderpath = #FOLDERPATH
     OR 
	f.folderpath LIKE '%Enter in Search Parameter%'
	    AND
		g.Active = 1
		AND
		g.IsPersonal = 0	           
	ORDER BY 
		1,2,3,4,5