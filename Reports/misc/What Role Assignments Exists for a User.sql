SELECT    r.Name AS [Role]
          ,udn.DisplayName AS [Username]
            ,CASE
                WHEN g.IsPersonal = 1 THEN 'User'
                ELSE N'Group - ' + vgd.DisplayName
            END AS [Permission From]
        FROM tbRoleToGroup rg WITH (NOLOCK)
            INNER JOIN tbRole r WITH (NOLOCK)
                ON rg.RoleId = r.RoleId
                AND r.RoleType = 1
            INNER JOIN tbGroup g WITH (NOLOCK)
                ON rg.GroupId = g.GroupId
            INNER JOIN tbUserGroup ug WITH (NOLOCK)
                ON g.GroupId = ug.GroupId
            INNER JOIN vGroupDisplayName vgd WITH (NOLOCK)
                on g.GroupId = vgd.GroupId
            INNER JOIN tbUser u WITH (NOLOCK)
                ON ug.UserId = u.UserId
            INNER JOIN vUserDisplayName udn WITH (NOLOCK)
                ON u.UserId = udn.UserId
        WHERE
            u.Enabled = 1 and g.IsPersonal =1 
        ORDER BY
            1 ASC ,2 ASC ,3
