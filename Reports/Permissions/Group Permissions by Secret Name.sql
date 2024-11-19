SELECT DISTINCT
	s.SecretID AS [Secret ID]
	,f.FolderPath AS [Folder]
	,s.SecretName AS [Secret Name]
	,g.GroupName AS [Group]
	,gsp.Permissions AS [Group permissions]

FROM 

vGroupSecretPermissions gsp

INNER JOIN tbGroup g ON gsp.GroupId = g.GroupID
INNER JOIN tbSecret s ON gsp.SecretId = s.SecretID
LEFT JOIN tbfolder f ON s.FolderId = f.FolderID
INNER JOIN vGroupDisplayName gdn WITH (NOLOCK)
				ON g.GroupId = gdn.GroupId
			LEFT JOIN tbUserGroup ug WITH (NOLOCK)
				ON g.GroupId = ug.GroupId
			LEFT JOIN tbUser u WITH (NOLOCK)
				ON ug.UserId = u.UserId 
				AND u.OrganizationId = 1
			LEFT JOIN vUserDisplayName udn WITH (NOLOCK)
				ON u.UserId = udn.UserId 

WHERE 

s.Active = 1 and g.GroupName NOT LIKE '%Everyone%' AND s.SecretName LIKE '%' + #CUSTOMTEXT + '%'
