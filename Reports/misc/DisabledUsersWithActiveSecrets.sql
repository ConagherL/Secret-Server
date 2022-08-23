SELECT DISTINCT
        udn.DisplayName AS [Person]
        ,udn.UserName As [UserLogin]
        ,ISNULL(f.FolderPath, N'No folder assigned') as [Folder Path]
        ,s.SecretName AS [Secret Name]
        ,st.SecretTypeName AS [Secret Template]
        ,gsp.[Permissions]
        ,gdn.DisplayName AS 'Person/Grp'
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
    INNER JOIN tbUserGroup ug WITH (NOLOCK)
        ON sgp.GroupId = ug.GroupId
    INNER JOIN tbSecretType st WITH (NOLOCK)
        ON s.SecretTypeId = st.SecretTypeId
    LEFT JOIN tbFolder f WITH (NOLOCK)
        ON s.FolderId = f.FolderId
    INNER JOIN vUserDisplayName udn WITH (NOLOCK)
        ON udn.UserId = ug.UserId
    INNER JOIN tbUser u WITH (NOLOCK)
        ON u.UserId = ug.UserId
    INNER JOIN vGroupSecretPermissions gsp
        ON sgp.GroupId = gsp.GroupId AND s.SecretID = gsp.SecretId
    INNER JOIN vGroupDisplayName gdn WITH (NOLOCK)
        ON gsp.GroupId = gdn.GroupId    
    WHERE
        u.Enabled = 0
        AND
        s.active = 1
        AND 
        st.OrganizationId = #organizationID
        AND
        gsp.Permissions = 'List/View'

         ORDER BY
        1,2,3,4,5,6,7,8