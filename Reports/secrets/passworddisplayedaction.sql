SELECT 
		a.DateRecorded AS [Date Recorded],
		upn.displayname AS [User],
		ISNULL(f.FolderPath, N'No folder assigned') as [Folder Path],
		s.secretname As [Secret Name],
		a.Action,
		a.Notes,
		a.ipaddress AS [IP Address]
	FROM tbauditsecret a WITH (NOLOCK)
	INNER JOIN tbuser u WITH (NOLOCK)
		ON u.userid = a.userid
		AND u.OrganizationId = #Organization
	INNER JOIN vUserDisplayName upn WITH (NOLOCK)
		ON u.UserId = upn.UserId
	INNER JOIN tbsecret s WITH (NOLOCK)
		ON s.secretid = a.secretid 
	LEFT JOIN tbFolder f WITH (NOLOCK)
		ON s.FolderId = f.FolderId
	WHERE 
		a.DateRecorded >= #StartDate
		AND
		a.DateRecorded <= #EndDate
		AND
		a.Action like '%Password Displayed%'	
	ORDER BY 
		1 DESC,2, 3,4,5,6,7