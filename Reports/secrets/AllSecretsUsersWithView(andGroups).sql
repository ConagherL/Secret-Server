SELECT DISTINCT
        udn.DisplayName AS [UserDisplayName]
        ,ISNULL(f.FolderPath, N'No folder assigned') as [Folder Path]
		,g.GroupName AS [GroupName]
        ,s.SecretName AS [Secret Name]
        ,st.SecretTypeName AS [Secret Template]
        ,s.SecretId
    FROM tbSecret s WITH (NOLOCK)
    INNER JOIN tbGroupSecretPermission sgp WITH (NOLOCK)
        ON s.SecretId = sgp.SecretId
    INNER JOIN tbRole r
        ON sgp.SecretAccessRoleId = r.RoleId
    INNER JOIN tbRoleToRolePermission rtr
        ON r.RoleId = rtr.RoleId
    INNER JOIN tbUserGroup ug WITH (NOLOCK)
        ON sgp.GroupId = ug.GroupId
    INNER JOIN tbSecretType st WITH (NOLOCK)
        ON s.SecretTypeId = st.SecretTypeId
    LEFT JOIN tbFolder f WITH (NOLOCK)
        ON s.FolderId = f.FolderId
    INNER JOIN vUserDisplayName udn WITH (NOLOCK)
        ON udn.UserId = ug.UserId
	INNER JOIN tbGroup g
		ON ug.GroupID = g.GroupID
    WHERE
        s.Active = 1
        AND
        rtr.RolePermissionId = 10064
    ORDER BY
        1,2,3,4,5