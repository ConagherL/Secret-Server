
		SELECT	
			gdn.DisplayName AS [Group Name]
			,udn.DisplayName AS [Usernames]
			,CASE g.Active 
			WHEN 1 THEN 'Yes'
			WHEN 0 THEN 'No'
			END AS [Is Group Active]
		FROM tbGroup g WITH (NOLOCK)
			INNER JOIN vGroupDisplayName gdn WITH (NOLOCK)
				ON g.GroupId = gdn.GroupId
			LEFT JOIN tbUserGroup ug WITH (NOLOCK)
				ON g.GroupId = ug.GroupId
			LEFT JOIN tbUser u WITH (NOLOCK)
				ON ug.UserId = u.UserId 
			
			LEFT JOIN vUserDisplayName udn WITH (NOLOCK)
				ON u.UserId = udn.UserId 
		WHERE
			(u.[Enabled] = 1 OR u.UserId IS NULL)
			AND
			g.IsPersonal = 0
			AND
			g.SystemGroup = 0
			AND 
			g.Active = 1 
			AND 
			udn.DisplayName IS NOT NULL
		ORDER BY
			[Group Name] ASC ,2 
		