SELECT DISTINCT ISNULL(f.FolderPath, N'No folder assigned') AS [Folder Path], 
		s.SecretName AS [Secret Name], 
		st.SecretTypeName AS [Secret Template], 
		s.SecretID
FROM	tbSecret AS s WITH (NOLOCK) 
		INNER JOIN tbGroupSecretPermission AS sgp WITH (NOLOCK) ON s.SecretID = sgp.SecretID 
		INNER JOIN tbUserGroup AS ug WITH (NOLOCK) ON sgp.GroupID = ug.GroupID AND ug.UserID = #User 
		INNER JOIN tbUser AS u WITH (NOLOCK) ON ug.UserID = u.UserId
		INNER JOIN tbGroup AS g WITH (NOLOCK) ON sgp.GroupID = g.GroupID AND (g.Active = 1 OR g.IsPersonal = 1) 
		INNER JOIN tbRole AS r ON sgp.SecretAccessRoleId = r.RoleId 
		INNER JOIN tbRoleToRolePermission AS rtr ON r.RoleId = rtr.RoleId 
		INNER JOIN tbSecretType AS st WITH (NOLOCK) ON s.SecretTypeID = st.SecretTypeID 
		LEFT OUTER JOIN tbFolder AS f WITH (NOLOCK) ON s.FolderId = f.FolderID
WHERE	s.Active = 1 
		AND st.OrganizationId = 1
		AND rtr.RolePermissionId = 10064
		AND NOT EXISTS
		(
			SELECT	1
			FROM	tbAuditSecret AS auds
			WHERE	[Action] = 'CHANGE PASSWORD'
					 AND SecretId = s.SecretID
					 AND DateRecorded >= #StartDate
					 AND DateRecorded <= #EndDate		
		)
ORDER BY 1,2,3, 4 OPTION (FORCE ORDER)