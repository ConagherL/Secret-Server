SELECT DISTINCT
        ISNULL(f.FolderPath, N'No folder assigned') as [Folder Path]
        ,s.SecretName AS [Secret Name]
        ,st.SecretTypeName AS [Secret Template]
        ,gsp.[Permissions]
        ,gdn.DisplayName AS 'Group'
        ,CASE gsp.[Inherit Permissions]
            WHEN 'No' THEN 'Secret'
            WHEN 'Yes' THEN (
                CASE f.EnableInheritPermissions
                    WHEN NULL THEN 'Folder'
                    WHEN 1 THEN 'A Parent Folder'
                    WHEN 0 THEN 'Folder'
                END)
        END AS [Permissions On]
        ,s.SecretId
    FROM tbSecret s WITH (NOLOCK)
    INNER JOIN tbGroupSecretPermission sgp WITH (NOLOCK)
        ON s.SecretId = sgp.SecretId
    INNER JOIN tbRole r
        ON sgp.SecretAccessRoleId = r.RoleId
    INNER JOIN tbRoleToRolePermission rtr
        ON r.RoleId = rtr.RoleId
    INNER JOIN tbSecretType st WITH (NOLOCK)
        ON s.SecretTypeId = st.SecretTypeId
    LEFT JOIN tbFolder f WITH (NOLOCK)
        ON s.FolderId = f.FolderId
    INNER JOIN vGroupSecretPermissions gsp WITH (NOLOCK)
        ON sgp.GroupId = gsp.GroupId AND s.SecretID = gsp.SecretId
    INNER JOIN tbGroup g WITH (NOLOCK)
        ON gsp.GroupId = g.GroupId
    INNER JOIN vGroupDisplayName gdn WITH (NOLOCK)
        ON gsp.GroupId = gdn.GroupId        
    WHERE
        s.Active = 1
        AND
        st.OrganizationId = 1 --modify organization
        AND 
        g.GroupId = 700 --modify groupId
        AND
        g.Active = 1
        AND
        g.IsPersonal = 0
        AND
		s.FolderId IN ('106','171','234','688') --modify folderId
		AND
		gsp.[Permissions] = 'List/View/Edit' --'List/View/Edit/Owner'
		

    ORDER BY
        1,2,3,4,5,6,7