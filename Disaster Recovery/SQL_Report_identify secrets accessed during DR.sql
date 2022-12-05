SELECT  
		s.secretname AS [Secret Name]
		,s.ConcurrencyID AS [Concurrency ID]
		,s.IsReplicated AS [Replicated]
		,a.latestdaterecorded AS [Latest Date Recorded]
		,u.displayname AS [SSUser]
		,ISNULL(f.FolderPath, N'No folder assigned') AS [Folder Path]
		,a.ipaddress AS [IP Address]
	FROM (	
		SELECT 
			audit.secretid,
			audit.userid,
			audit.ipaddress,
			Max(audit.daterecorded) AS 'latestdaterecorded'
		FROM tbauditsecret audit WITH (NOLOCK)
		INNER JOIN tbUser WITH (NOLOCK)
			ON audit.UserId = tbUser.UserID
			AND tbUser.OrganizationId = 1
		WHERE 
			audit.DateRecorded >= #STARTTODAY
			AND
			audit.DateRecorded <= #ENDTODAY	
		GROUP BY 
			audit.userid,
			audit.secretid,
			audit.ipaddress) a
	INNER JOIN vUserDisplayName u WITH (NOLOCK)
		ON u.userid = a.userid
	INNER JOIN tbsecret s WITH (NOLOCK)
		ON s.secretid = a.secretid 
	LEFT JOIN tbFolder f WITH (NOLOCK)
		ON s.FolderId = f.FolderId
	WHERE
		s.IsReplicated = 1
		AND
		s.Active = 1
	ORDER BY 
		1 DESC, 2, 3, 4, 5
